resource_name :osl_synapse
provides :osl_synapse
unified_mode true

default_action :create

property :appservices, Array, default: []
property :config, Hash
property :container_name, String, default: lazy { "synapse-#{domain}" }
property :domain, String, name_property: true
property :path, String, default: lazy { "/opt/#{container_name}" }
property :pg_host, String
property :pg_name, String
property :pg_username, String
property :pg_password, String
property :port, Integer, default: 8008
property :reg_key, String, default: lazy { osl_matrix_genkey(path + container_name) }
property :tag, String, default: 'latest'
property :sensitive, [true, false], default: true

action :create do
  include_recipe 'osl-docker'

  # Merge the defined properties into the config.
  config = new_resource.config.merge(
    osl_homeserver_defaults(
      new_resource.domain,
      {
        host: new_resource.pg_host,
        database: new_resource.pg_name,
        username: new_resource.pg_username,
        password: new_resource.pg_password,
      },
      new_resource.appservices
    )
  ) { |_key, config_value, default_value| config_value || default_value }

  # Initalize the matrix manager
  user 'synapse' do
    system true
  end

  # Server root
  directory new_resource.path do
    owner 'synapse'
    mode '750'
  end

  # Keys, Compose, and appservice file directories
  %w(keys compose appservice).each do |dir|
    directory "#{new_resource.path}/#{dir}" do
      owner 'synapse'
      mode '700'
    end
  end

  # Generate secret keys for Synapse. Only generate once.
  file "#{new_resource.path}/keys/registration.key" do
    content new_resource.reg_key
    owner 'synapse'
    mode '400'
    sensitive true
    action :create_if_missing
  end

  # Generate homeserver.yaml
  file "#{new_resource.path}/homeserver.yaml" do
    content osl_yaml_dump(config)
    owner 'synapse'
    group 'synapse'
    mode '400'
    sensitive true
  end

  config_compose = {
    'services' => {
      'synapse' => {
        'image' => "matrixdotorg/synapse:#{new_resource.tag}",
        'ports' => ["#{new_resource.port}:8008", '8448:8448'],
        'volumes' => [
          "#{new_resource.path}:/data",
        ],
        'user' => osl_synapse_user,
        'restart' => 'always',
        'depends_on' => new_resource.appservices,
      },
    },
  }

  # Generate compose file
  file "#{new_resource.path}/compose/docker-synapse.yaml" do
    content osl_yaml_dump(config_compose)
    owner 'synapse'
    group 'synapse'
    mode '400'
    sensitive true
  end
end
