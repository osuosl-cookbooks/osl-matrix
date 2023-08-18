resource_name :osl_matrix
provides :osl_matrix
unified_mode true

default_action :create

property :app_services, Array, default: []
property :config, String
property :domain, String, name_property: true
property :pg_host, String
property :pg_name, String
property :pg_username, String
property :pg_password, String
property :tag, String, default: 'latest'
property :use_sqlite, [true, false], default: false

action :create do
  require 'securerandom'

  # Initalize the synapse user
  user 'synapse-host' do
    system true
  end

  # Synapse configuration
  directory '/srv/synapse' do
    owner 'synapse-host'
    mode '750'
  end

  # Keys directory
  directory '/srv/synapse/keys' do
    owner 'synapse-host'
    mode '700'
  end

  # Create the docker network for Synapse-related items
  docker_network 'synapse-network'

  # Generate secret keys for Synapse. Only generate once.
  file '/srv/synapse/keys/registration.key' do
    content SecureRandom.base64(32)
    owner 'synapse-host'
    mode '400'

    action :create_if_missing
  end

  # Generate homeserver.yaml
  template '/srv/synapse/homeserver.yaml' do
    source 'homeserver.yaml.erb'
    cookbook 'osl-matrix'
    owner 'synapse-host'
    mode '600'
    variables(
      appservices: new_resource.app_services,
      domain: new_resource.domain,
      pg_host: new_resource.pg_host,
      pg_name: new_resource.pg_name,
      pg_username: new_resource.pg_username,
      pg_password: new_resource.pg_password,
      sqlite: new_resource.use_sqlite,
      user_config: new_resource.config,
    )
  end

  nSynapseUID = shell_out('id -u synapse-host').stdout

  docker_image 'matrixdotorg/synapse'

  docker_container 'osl-matrix-synapse' do
    repo 'matrixdotorg/synapse'
    port ['8008:8008']
    volumes ['/srv/synapse/:/data']
    env ["UID=#{nSynapseUID}"]
    subscribes :reload, 'template[/srv/synapse/homeserver.yaml]'
  end

  # Connect the synapse server to the docker network
  docker_network 'synapse-network' do
    container 'osl-matrix-synapse'
    action :connect
  end

  # Connect the extra services
  new_resource.app_services.each do |container|
    docker_network 'synapse-network' do
      container container
      action :connect
    end
  end
end
