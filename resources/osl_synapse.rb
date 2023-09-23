resource_name :osl_synapse
provides :osl_synapse
unified_mode true

default_action :create

property :app_services, Array, default: []
property :config, String
property :domain, String, name_property: true
property :name, String
property :network, String
property :path, String
property :pg_host, String
property :pg_name, String
property :pg_username, String
property :pg_password, String
property :port, Integer, default: 8008
property :tag, String, default: 'latest'
property :use_sqlite, [true, false], default: false

action :create do
  # Check to see if a name was given
  new_resource.name = "matrix-synapse-#{new_resource.domain}" unless new_resource.name
  # Get the path to use for this resource
  new_resource.path = "/opt/synapse-#{new_resource.name}" unless new_resource.path
  # Set the docker network
  new_resource.network = "synapse-network-#{new_resource.name}" unless new_resource.network

  include_recipe 'osl-docker'

  # Initalize the synapse user
  user 'synapse' do
    system true
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
    content osl_matrix_genkey
    owner 'synapse'
    mode '400'

    action :create_if_missing
  end

  # Generate homeserver.yaml
  template "#{new_resource.path}/homeserver.yaml" do
    source 'homeserver.yaml.erb'
    cookbook 'osl-matrix'
    owner 'synapse'
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

  docker_image 'matrixdotorg/synapse'

  docker_container new_resource.name do
    repo 'matrixdotorg/synapse'
    port ["#{new_resource.port}:8008"]
    volumes ["#{new_resource.path}:/data"]
    env ["UID=#{Etc.getpwnam('synapse').uid.to_s}"]
    subscribes :restart, "template[#{new_resource.path}/homeserver.yaml]"
    restart_policy 'always'
  end

  # Connect the synapse server to the docker network
  docker_network new_resource.network do
    container new_resource.name
    action :connect
  end

end
