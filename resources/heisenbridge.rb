# osl_heisenbridge
#
# Heisenbridge is an IRC bouncer for a Matrix server

resource_name :osl_heisenbridge
provides :osl_heisenbridge
unified_mode true

default_action :create

property :container_name, String, name_property: true
property :port, Integer, default: 9898
property :host_domain, String, required: true
property :host_name, String, default: lazy { "synapse-#{host_domain}" }
property :host_path, String, default: lazy { "/opt/#{host_name}" }
property :key_appservice, String, default: lazy { osl_matrix_genkey(host_name + container_name) }
property :key_homeserver, String, default: lazy { osl_matrix_genkey(container_name + host_name) }
property :tag, String, default: 'latest'
property :sensitive, [true, false], default: true

action :create do
  # Pull down the latest version
  docker_image 'hif1/heisenbridge' do
    tag new_resource.tag
  end

  # Generate the app service file
  osl_synapse_appservice(
    'heisenbridge',
    "http://#{new_resource.container_name}:#{new_resource.port}",
    new_resource.key_appservice,
    new_resource.key_homeserver,
    'heisenbridge',
    {
      'users' => [
        {
          'exclusive' => true,
          'regex' => '@irc_.*',
        },
      ],
    }
  )

  # Generate the compose config
  config_compose = {
    'services' => {
      new_resource.container_name => {
        'entrypoint' => "python -m heisenbridge -c /data/#{new_resource.container_name}.yaml http://synapse:8008",
        'image' => "hif1/heisenbridge:#{new_resource.tag}",
        'volumes' => [
          "#{new_resource.host_path}/appservice/#{new_resource.container_name}.yaml:/data/#{new_resource.container_name}.yaml",
        ],
        'user' => osl_synapse_user,
        'restart' => 'always',
      },
    },
  }

  # Generate compose file
  file "#{new_resource.host_path}/compose/docker-#{new_resource.container_name}.yaml" do
    content osl_yaml_dump(config_compose)
    owner 'synapse'
    group 'synapse'
    mode '400'
    sensitive true
  end
end
