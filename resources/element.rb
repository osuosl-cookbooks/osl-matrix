# Element Web Application
# This resource allows for the deployment of Element, a Matrix client, as a website.

resource_name :osl_element
provides :osl_element
unified_mode true

default_action :create

property :matrix_domain, String, name_property: true
property :port, Integer, default: 8000
property :background, String
property :logo, String

action :create do
  include_recipe 'osl-docker' do
    notifies :restart, 'docker_container[element_webapp]'
  end

  volumes = ['/opt/element/config.json:/app/config.json:ro']

  directory '/opt/element'

  # Custom branding
  enable_branding = new_resource.background || new_resource.logo
  
  cookbook_file "/opt/element/background#{::File.extname(new_resource.background)}" do
    source new_resource.background
    only_if { new_resource.background }
  end

  volumes.push("/opt/element/background#{::File.extname(new_resource.background)}:/app/assets/background#{::File.extname(new_resource.background)}:ro") if new_resource.background

  cookbook_file "/opt/element/logo#{::File.extname(new_resource.logo)}" do
    source new_resource.logo
    only_if { new_resource.logo }
  end

  volumes.push("/opt/element/logo#{::File.extname(new_resource.logo)}:/app/assets/logo#{::File.extname(new_resource.logo)}:ro") if new_resource.logo

  template '/opt/element/config.json' do
    source 'element-config.json.erb'
    cookbook 'osl-matrix'
    variables(fqdn: new_resource.matrix_domain, branding: enable_branding)
    sensitive true
    notifies :redeploy, 'docker_container[element_webapp]'
  end

  docker_image 'vectorim/element-web' do
    tag 'latest'
    notifies :redeploy, 'docker_container[element_webapp]', :immediately
  end

  docker_container 'element_webapp' do
    repo 'vectorim/element-web'
    port ["#{new_resource.port}:80"]
    volumes volumes
  end
end
