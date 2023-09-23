# osl_heisenbridge
#
# Heisenbridge is an IRC bouncer for a Matrix server

resource_name :osl_heisenbridge
provides :osl_heisenbridge
unified_mode true

default_action :create

property :container_name, String, name_property: true
property :port, Integer, default: 9898
property :matrix_host_resource, Symbol, required: true, default: :osl_synapse
property :matrix_host_domain, String, required: true

action :create do
  # Get the required information taken from the matrix host resource
  matrix_resource = find_resource(new_resource.matrix_host_resource, new_resource.matrix_host_domain)
  path = matrix_resource.path
  name = matrix_resource.name
  network = matrix_resource.network

  # Pull down the heisenbridge image
  docker_image 'hif1/heisenbridge'

  # Generate the app service file
  template "#{path}/#{new_resource.container_name}.yaml" do
    source 'appservice.erb'
    cookbook 'osl-matrix'
    mode '644'
    variables(
      id: 'heisenbridge',
      url: "http://#{new_resource.container_name}:#{new_resource.port}",
      matrix_rand_appservice: 'appservicekey',
      matrix_rand_homeserver: 'homeserverkey',
      service: 'heisenbridge',
      namespaces: {
        users: [
          {
            exclusive: true,
            regex: '\'@irc_.*\''
          }
        ]
      }
    )
  end

  # Create the docker container
  docker_container new_resource.container_name do
    repo 'hif1/heisenbridge'
    volumes ["#{path}/#{new_resource.container_name}.yaml:/data/#{new_resource.container_name}.yaml"]
    entrypoint "python -m heisenbridge -c /data/#{new_resource.container_name}.yaml http://#{name}:8008"
    restart_policy 'always'
  end

  # Connect to the network
  docker_network network do
    container new_resource.container_name
    action :connect
  end
end
