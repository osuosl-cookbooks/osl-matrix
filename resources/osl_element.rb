# Element Web Application
# This resource allows for the deployment of Element, a Matrix client, as a website.

resource_name :osl_element
provides :osl_element
unified_mode true

default_action :create

property :domain, String, name_property: true
property :matrix_domain, String

action :create do
  include_recipe 'osl-docker'
  include_recipe 'osl-nginx'

  hostname node['hostname'] do
    aliases [new_resource.domain]
  end

  directory '/srv/element'

  cookbook_file '/srv/element/config.json' do
    source 'element-config.json'
    cookbook 'osl-matrix'
  end

  docker_image 'vectorim/element-web'

  docker_container 'element_webapp' do
    repo 'vectorim/element-web'
    port ['8000:80']
    volumes ['/srv/element/config.json:/app/config.json']
  end

  template 'Element Reverse Proxy' do
    source 'element-web.conf.erb'
    path "/etc/nginx/conf.d/#{new_resource.domain}.conf"
    cookbook 'osl-matrix'
    variables('fqdn': new_resource.domain)

    owner 'nginx'
    group 'nginx'

    notifies :reload, 'nginx_service[osuosl]', :immediately
  end
end
