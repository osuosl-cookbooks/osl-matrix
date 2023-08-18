# osl_heisenbridge
#
# Heisenbridge is an IRC bouncer for a Matrix server

resource_name :osl_heisenbridge
provides :osl_heisenbridge
unified_mode true

default_action :create

property :container_name, String, name_property: true

action :create do
  # Pull down the heisenbridge image
  docker_image 'hif1/heisenbridge'
  
  # Generate the app service file
  execute 'heisenbridge app service' do
    command "docker run --volume=/srv/synapse:/data hif1/heisenbridge  'python -m heisenbridge' -c /data/#{new_resource.container_name}.yaml --generate --listen-address #{new_resource.container_name}"
    creates "/srv/synapse/#{new_resource.container_name}.yaml"
  end

  # Update the file's permissions for synapse-host
  file 'update heisenbridge perms' do
    file "/srv/synapse/#{new_resource.container_name}.yaml"
    mode '644'
  end

  # Create the docker container and queue it for a delayed deployment
  docker_container new_resource.container_name do
    repo 'hif1/heisenbridge'
    volumes ["/srv/synapse/#{new_resource.container_name}.yaml:/data/#{new_resource.container_name}.yaml"]
    entrypoint "python -m heisenbridge -c /data/#{new_resource.container_name}.yaml http://osl-matrix-synapse:8008"
  end

  # Add heisenbridge as an additional app service
  # node.default['osl-matrix']['app-service']['osl-irc-bridge'] = '/data/heisenbridge.yaml'
end
