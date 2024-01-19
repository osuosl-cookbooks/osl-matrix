resource_name :osl_synapse
provides :osl_synapse
unified_mode true

default_action :create

property :app_services, Array, default: []
property :config, Hash
property :domain, String, name_property: true
property :container_name, String, default: lazy { "matrix-synapse-#{domain}" }
property :network, String, default: lazy { "synapse-network-#{container_name}" }
property :path, String, default: lazy { "/opt/synapse-#{container_name}" }
property :pg_host, String
property :pg_name, String
property :pg_username, String
property :pg_password, String
property :port, Integer, default: 8008
property :reg_key, String, default: lazy { osl_matrix_genkey(network + path + container_name) }
property :tag, String, default: 'latest'

action :create do
  include_recipe 'osl-docker'

  # Merge the defined properties into the config.
  new_resource.config.merge!(
    osl_homeserver_defaults(
      new_resource.domain,
      {
        host: new_resource.pg_host,
        database: new_resource.pg_name,
        username: new_resource.pg_username,
        password: new_resource.pg_password,
      },
      new_resource.app_services
    )
  ) { |_key, config_value, default_value| config_value || default_value }

  # Initalize the synapse user
  user 'synapse' do
    system true
    # Do an initial server restart after the first run.
    notifies :restart, "docker_container[#{new_resource.container_name}]", :delayed
  end

  # Synapse configuration
  directory new_resource.path do
    owner 'synapse'
    mode '750'
  end

  # Keys directory
  directory "#{new_resource.path}/keys" do
    owner 'synapse'
    mode '700'
  end

  # Create the docker network for Synapse-related items
  docker_network new_resource.network

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
    content YAML.dump(new_resource.config).lines[1..-1].join
    owner 'synapse'
    group 'synapse'
    mode '400'
    sensitive true
  end

  docker_image 'matrixdotorg/synapse'

  docker_container new_resource.container_name do
    repo 'matrixdotorg/synapse'
    port ["#{new_resource.port}:8008", '8448:8448']
    volumes ["#{new_resource.path}:/data"]
    user "#{Etc.getpwnam('synapse').uid.to_s}:#{Etc.getpwnam('synapse').gid.to_s}"
    subscribes :restart, "template[#{new_resource.path}/homeserver.yaml]"
    restart_policy 'always'
  end

  # Connect the synapse server to the docker network
  docker_network new_resource.network do
    container new_resource.container_name
    action :connect
  end
end

# Restart the synapse container.
action :restart do
  docker_container new_resource.container_name do
    action :restart
  end
end
