# Synapse Admin Web Application
# This resource allows for the deployment of an Admin web-interface for Matrix Synapse servers.
# NOTE: Requires /_synapse/admin to be reachable from the browser

resource_name :osl_synapse_admin
provides :osl_synapse_admin
unified_mode true

default_action :create

property :matrix_domain, String, name_property: true
property :port, Integer, default: 8080
property :force_domain, [true, false], default: false

action :create do
  include_recipe 'osl-docker' do
    notifies :restart, 'docker_container[synapse_admin_webapp]'
  end

  directory '/opt/synapse_admin' do
    only_if { new_resource.force_domain }
  end

  file '/opt/synapse_admin/config.json' do
    content JSON.dump({ 'restrictBaseUrl' => new_resource.matrix_domain })
    only_if { new_resource.force_domain }
  end

  docker_image 'awesometechnologies/synapse-admin'

  docker_container 'synapse_admin_webapp' do
    repo 'awesometechnologies/synapse-admin'
    port ["#{new_resource.port}:80"]
    volumes ['/opt/synapse_admin/config.json:/app/config.json:ro'] if new_resource.force_domain
  end
end
