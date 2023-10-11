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
property :tag, String, default: 'latest'
property :use_sqlite, [true, false], default: false

action :create do
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
    sensitive true
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
      # For the YAML dump, we need to remove the document start line.
      user_config: YAML.dump(new_resource.config).lines[1..-1].join
    )
    sensitive true
  end

  docker_image 'matrixdotorg/synapse'

  docker_container new_resource.container_name do
    repo 'matrixdotorg/synapse'
    port ["#{new_resource.port}:8008"]
    volumes ["#{new_resource.path}:/data"]
    env ["UID=#{Etc.getpwnam('synapse').uid.to_s}"]
    subscribes :restart, "template[#{new_resource.path}/homeserver.yaml]"
    restart_policy 'always'
  end

  # Connect the synapse server to the docker network
  docker_network new_resource.network do
    container new_resource.container_name
    action :connect
  end
end
