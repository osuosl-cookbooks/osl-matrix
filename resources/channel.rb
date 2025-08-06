resource_name :osl_matrix_channel
provides :osl_matrix_channel
unified_mode true

property :channel_alias, String, name_property: true
property :display_name, String, required: true
property :domain, String, default: lazy { URI.parse(homeserver_url).host }
property :homeserver_url, String, required: true
property :public, [true, false], default: false
property :retries, Integer, default: 10
property :retry_delay, Integer, default: 20
property :topic, String
property :user, String, default: 'admin'

default_action :create

action :create do
  full_alias = "##{new_resource.channel_alias}:#{new_resource.domain}"
  access_token = ::File.read("/opt/synapse-#{new_resource.domain}/keys/#{new_resource.user}-access_token.key")

  check_server_readiness(new_resource.homeserver_url)

  unless channel_alias_exists?(new_resource.homeserver_url, full_alias)
    converge_by "creating channel #{full_alias}" do
      create_channel(
        new_resource.homeserver_url,
        access_token,
        new_resource.display_name,
        new_resource.channel_alias,
        new_resource.topic,
        new_resource.public
      )
    end
  end
end
