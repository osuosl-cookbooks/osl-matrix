resource_name :osl_synapse_service
provides :osl_synapse_service
unified_mode true

default_action :create

property :appservices, Array, default: []
property :config, Hash
property :config_hookshot, Hash
property :domain, String, name_property: true
property :pg_host, String
property :pg_name, String
property :pg_username, String
property :pg_password, String
property :port, Integer, default: 8008
property :reg_key, String, default: lazy { osl_matrix_genkey(domain) }
property :tag, String, default: 'latest'
property :tag_heisenbridge, String, default: 'latest'
property :tag_hookshot, String, default: 'latest'
property :sensitive, [true, false], default: true

action :create do
  synapse_path = "/opt/synapse-#{new_resource.domain}"

  compose_files = new_resource.appservices.map { |appservice| "docker-#{appservice}.yaml" }
  compose_files.push('docker-synapse.yaml')

  # Run the docker compose, but only do so after the converge finishes everything else
  osl_dockercompose 'synapse' do
    directory "#{synapse_path}/compose"
    config compose_files
    action :nothing
  end

  # Generate Synapse Path And Container
  osl_synapse new_resource.domain do
    appservices new_resource.appservices
    config new_resource.config
    pg_host new_resource.pg_host
    pg_name new_resource.pg_name
    pg_username new_resource.pg_username
    pg_password new_resource.pg_password
    port new_resource.port
    reg_key new_resource.reg_key
    tag new_resource.tag
    notifies :rebuild, 'osl_dockercompose[synapse]'
  end

  # Check to see if we are initalizing any addons
  osl_heisenbridge 'heisenbridge' do
    host_domain new_resource.domain
    tag new_resource.tag_heisenbridge
    only_if { new_resource.appservices.include?('heisenbridge') }
    notifies :rebuild, 'osl_dockercompose[synapse]'
  end

  osl_hookshot 'hookshot' do
    host_domain new_resource.domain
    config new_resource.config_hookshot
    tag new_resource.tag_hookshot
    only_if { new_resource.appservices.include?('hookshot') }
    notifies :rebuild, 'osl_dockercompose[synapse]'
  end
end
