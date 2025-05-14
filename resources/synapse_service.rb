resource_name :osl_synapse_service
provides :osl_synapse_service
unified_mode true

default_action :create

property :appservices, Array, default: []
property :config, Hash, default: {}
property :config_hookshot, Hash, default: {}
property :config_matrix_irc, Hash, default: {}
property :config_mjolnir, Hash, default: {}
property :domain, String, name_property: true
property :irc_users_regex, String, default: '@as-irc_.*'
property :key_github, String
property :pg_host, String
property :pg_name, String
property :pg_username, String
property :pg_password, String
property :port, Integer, default: 8008
property :fed_port, Integer, default: 8448
property :reg_key, String, default: lazy { osl_matrix_genkey(domain) }
property :tag, String, default: 'latest'
property :tag_heisenbridge, String, default: 'latest'
property :tag_hookshot, String, default: 'latest'
property :tag_matrix_irc, String, default: 'latest'
property :tag_mjolnir, String, default: 'latest'
property :sensitive, [true, false], default: true

action :create do
  synapse_path = "/opt/synapse-#{new_resource.domain}"
  compose_unique = osl_matrix_genkey(synapse_path)[0..5]

  compose_files = new_resource.appservices.map { |appservice| "docker-#{appservice}.yaml" }
  compose_files.push('docker-synapse.yaml')

  # Run the docker compose, but only do so after the converge finishes everything else
  osl_dockercompose compose_unique do
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
    fed_port new_resource.fed_port
    reg_key new_resource.reg_key
    tag new_resource.tag
    notifies :rebuild, "osl_dockercompose[#{compose_unique}]"
    notifies :restart, "osl_dockercompose[#{compose_unique}]"
  end

  # Check to see if we are initalizing any addons
  osl_heisenbridge 'heisenbridge' do
    host_domain new_resource.domain
    tag new_resource.tag_heisenbridge
    only_if { new_resource.appservices.include?('heisenbridge') }
    notifies :rebuild, "osl_dockercompose[#{compose_unique}]"
    notifies :restart, "osl_dockercompose[#{compose_unique}]"
  end

  osl_hookshot 'hookshot' do
    host_domain new_resource.domain
    config new_resource.config_hookshot
    tag new_resource.tag_hookshot
    key_github new_resource.key_github
    only_if { new_resource.appservices.include?('hookshot') }
    notifies :rebuild, "osl_dockercompose[#{compose_unique}]"
    notifies :restart, "osl_dockercompose[#{compose_unique}]"
  end

  osl_matrix_irc 'matrix-appservice-irc' do
    host_domain new_resource.domain
    config new_resource.config_matrix_irc
    tag new_resource.tag_matrix_irc
    users_regex new_resource.irc_users_regex
    only_if { new_resource.appservices.include?('matrix-appservice-irc') }
    notifies :rebuild, "osl_dockercompose[#{compose_unique}]"
    notifies :restart, "osl_dockercompose[#{compose_unique}]"
  end

  osl_mjolnir 'mjolnir' do
    host_domain new_resource.domain
    config new_resource.config_mjolnir
    tag new_resource.tag_mjolnir
    only_if { new_resource.appservices.include?('matrix-appservice-irc') }
    notifies :rebuild, "osl_dockercompose[#{compose_unique}]"
    notifies :restart, "osl_dockercompose[#{compose_unique}]"
  end
end
