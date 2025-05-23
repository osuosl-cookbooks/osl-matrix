# osl_mjolnir
#
# Mjolnir is a moderation bot for use in Matrix Synapse
# https://github.com/matrix-org/mjolnir

resource_name :osl_mjolnir
provides :osl_mjolnir
unified_mode true

default_action :create

property :config, Hash, default: {}
property :container_name, String, name_property: true
property :port, Integer, default: 9899
property :port_api, Integer, default: 9003
property :host_domain, String, required: true
property :host_name, String, default: lazy { "synapse-#{host_domain}" }
property :host_path, String, default: lazy { "/opt/#{host_name}" }
property :key_appservice, String, default: lazy { osl_matrix_genkey(host_name + container_name) }
property :key_homeserver, String, default: lazy { osl_matrix_genkey(container_name + host_name) }
property :bot_name, String, default: 'Auto Mod'
property :default_channel, String, default: lazy { "#mjolnir:#{host_domain}" }
property :tag, String, default: 'latest'
property :sensitive, [true, false], default: true

action :create do
  # Pull down the latest version
  docker_image 'matrixdotorg/mjolnir' do
    tag new_resource.tag
  end

  # Get the config from the new resource, and put into a mutable variable
  config = osl_mjolnir_defaults(new_resource.config)

  # Generate the app service file
  osl_synapse_appservice(
    'mjolnir',
    "http://#{new_resource.container_name}:#{new_resource.port}",
    new_resource.key_appservice,
    new_resource.key_homeserver,
    'mjolnir',
    {
      'users' => [
        {
          'exclusive' => true,
          'regex' => '@mjolnir_.*',
        },
      ],
    }
  )

  # Generate the compose config
  config_compose = {
    'services' => {
      new_resource.container_name => {
        'command' => "appservice -c /data/config.yaml -f /data/appservice.yaml -p #{new_resource.port}",
        'image' => "matrixdotorg/mjolnir:#{new_resource.tag}",
        'volumes' => [
          "#{new_resource.host_path}/appservice/#{new_resource.container_name}.yaml:/data/appservice.yaml:ro",
          "#{new_resource.host_path}/#{new_resource.container_name}-config.yaml:/data/config.yaml:ro",
          "#{new_resource.host_path}/appservice-data/#{new_resource.container_name}:/data/persistent",
        ],
        'ports' => [
          "#{new_resource.port_api}:#{new_resource.port_api}",
        ],
        'restart' => 'always',
        'depends_on' => ["#{new_resource.container_name}-db"],
      },
      "#{new_resource.container_name}-db" => {
        'image' => 'postgres',
        'environment' => {
          'POSTGRES_PASSWORD' => new_resource.key_homeserver,
          'POSTGRES_USER' => 'moderator',
        },
        'volumes' => [
          "#{new_resource.host_path}/appservice-data/mjolnir_init.sql:/docker-entrypoint-initdb.d/init.sql:ro",
          "#{new_resource.host_path}/appservice-data/#{new_resource.container_name}-db:/var/lib/postgresql/data",
        ],
      },
    },
  }

  # Generate the initSQL file
  cookbook_file "#{new_resource.host_path}/appservice-data/mjolnir_init.sql" do
    source 'mjolnir_init.sql'
    cookbook 'osl-matrix'
  end

  # Generate the config file
  file "#{new_resource.host_path}/#{new_resource.container_name}-config.yaml" do
    content osl_yaml_dump(config)
    owner 'synapse'
    group 'synapse'
    mode '400'
    sensitive true
  end

  # Generate compose file
  file "#{new_resource.host_path}/compose/docker-#{new_resource.container_name}.yaml" do
    content osl_yaml_dump(config_compose)
    owner 'synapse'
    group 'synapse'
    mode '400'
    sensitive true
  end
end
