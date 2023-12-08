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
property :host_name, String, default: lazy { "matrix-synapse-#{host_domain}" }
property :host_path, String, default: lazy { "/opt/synapse-#{host_name}" }
property :host_network, String, default: lazy { "synapse-network-#{host_name}" }
property :key_appservice, String, default: lazy { osl_matrix_genkey(host_name + container_name) }
property :key_homeserver, String, default: lazy { osl_matrix_genkey(host_network + container_name) }

action :create do
  new_resource.host_name = new_resource.host_name
  # Pull down the heisenbridge image
  docker_image 'hif1/heisenbridge'

  # Generate the app service file
  osl_synapse_appservice(
    'heisenbridge',
    "http://#{new_resource.container_name}:#{new_resource.port}",
    new_resource.key_appservice,
    new_resource.key_homeserver,
    'heisenbridge',
    {
      users: [
        {
          exclusive: true,
          regex: '\'@irc_.*\'',
        },
      ],
    }
  )

  # Create the docker container
  docker_container new_resource.container_name do
    repo 'hif1/heisenbridge'
    volumes ["#{new_resource.host_path}/#{new_resource.container_name}.yaml:/data/#{new_resource.container_name}.yaml"]
    entrypoint "python -m heisenbridge -c /data/#{new_resource.container_name}.yaml http://#{new_resource.host_name}:8008"
    restart_policy 'always'
  end

  # Connect to the network
  docker_network new_resource.host_network do
    container new_resource.container_name
    action :connect
  end
end
