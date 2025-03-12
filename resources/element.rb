# Element Web Application
# This resource allows for the deployment of Element, a Matrix client, as a website.

resource_name :osl_element
provides :osl_element
unified_mode true

default_action :create

property :matrix_domain, String, name_property: true
property :port, Integer, default: 8000

action :create do
  include_recipe 'osl-docker' do
    notifies :restart, 'docker_container[element_webapp]'
  end

  directory '/opt/element'

  template '/opt/element/config.json' do
    source 'element-config.json.erb'
    cookbook 'osl-matrix'
    variables(fqdn: new_resource.matrix_domain)
    sensitive true
  end

  docker_image 'vectorim/element-web' do
    tag 'latest'
    notifies :redeploy, 'docker_container[element_webapp]', :immediately
  end

  docker_container 'element_webapp' do
    repo 'vectorim/element-web'
    port ["#{new_resource.port}:80"]
    volumes ['/opt/element/config.json:/app/config.json']
  end
end
