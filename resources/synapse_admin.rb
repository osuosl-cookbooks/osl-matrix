# Synapse Admin Web Application
# This resource allows for the deployment of an Admin web-interface for Matrix Synapse servers.
# NOTE: Requires /_synapse/admin to be reachable from the browser

resource_name :osl_synapse_admin
provides :osl_synapse_admin
unified_mode true

default_action :create

property :docker_container, String, name_property: true
property :home_server, [String, Array]
property :port, Integer, default: 8080

action :create do
  include_recipe 'osl-docker'

  directory "/opt/synapse_admin_#{new_resource.docker_container}" do
    only_if { new_resource.home_server }
  end

  file "/opt/synapse_admin_#{new_resource.docker_container}/config.json" do
    content JSON.dump({ 'restrictBaseUrl' => new_resource.home_server })
    only_if { new_resource.home_server }
  end

  docker_image 'awesometechnologies/synapse-admin' do
    notifies :redeploy, "docker_container[#{new_resource.docker_container}]"
  end

  docker_container new_resource.docker_container do
    repo 'awesometechnologies/synapse-admin'
    port ["#{new_resource.port}:80"]
    volumes ["/opt/synapse_admin_#{new_resource.docker_container}/config.json:/app/config.json:ro"] if new_resource.home_server
  end
end
