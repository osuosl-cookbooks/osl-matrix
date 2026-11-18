# Synapse Admin Web Application
# Deploys Ketesa (etkecc/ketesa, the maintained fork of Synapse Admin) as an admin web-interface for Synapse.
# NOTE: Requires /_synapse/admin to be reachable from the browser

resource_name :osl_synapse_admin
provides :osl_synapse_admin
unified_mode true

default_action :create

property :container_name, String, name_property: true
property :home_server, [String, Array]
property :port, Integer, default: 8080
# v1 follows Ketesa's 1.x releases; latest is its nightly build of main
property :tag, String, default: 'v1'
property :config, Hash, default: {}

action :create do
  include_recipe 'osl-docker'

  config = synapse_admin_config
  config_dir = "/opt/synapse_admin_#{new_resource.container_name}"

  directory config_dir do
    not_if { config.empty? }
  end

  file "#{config_dir}/config.json" do
    content JSON.dump(config)
    not_if { config.empty? }
    notifies :redeploy, "docker_container[#{new_resource.container_name}]"
  end

  # Named per instance, since instances may pin different tags (and specs tell them apart by name)
  docker_image "ketesa_#{new_resource.container_name}" do
    repo 'etkecc/ketesa'
    tag new_resource.tag
    notifies :redeploy, "docker_container[#{new_resource.container_name}]"
  end

  # Ketesa's static-web-server listens on 8080 (SERVER_PORT) and reads /var/public/config.json
  docker_container new_resource.container_name do
    repo 'etkecc/ketesa'
    tag new_resource.tag
    port ["#{new_resource.port}:8080"]
    volumes ["#{config_dir}/config.json:/var/public/config.json:ro"] unless config.empty?
  end
end

action_class do
  # config.json: the extra settings, then restrictBaseUrl when a home server is set
  def synapse_admin_config
    hs = new_resource.home_server
    return new_resource.config.dup if hs.nil? || hs.empty?

    new_resource.config.merge('restrictBaseUrl' => hs)
  end
end
