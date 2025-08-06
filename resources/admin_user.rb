resource_name :osl_matrix_admin_user
provides :osl_matrix_admin_user
unified_mode true

property :domain, String, default: lazy { URI.parse(homeserver_url).host }
property :homeserver_url, String, required: true
property :password, String, required: true, sensitive: true
property :retries, Integer, default: 10
property :retry_delay, Integer, default: 20
property :username, String, name_property: true

default_action :create

action :create do
  reg_key = ::File.read("/opt/synapse-#{new_resource.domain}/keys/registration.key")
  access_token_file = "/opt/synapse-#{new_resource.domain}/keys/#{new_resource.username}-access_token.key"

  unless ::File.exist?(access_token_file)
    converge_by "registering initial admin user @#{new_resource.username}" do
      check_server_readiness(new_resource.homeserver_url)

      access_token = register_initial_admin(
        new_resource.homeserver_url,
        new_resource.username,
        new_resource.password,
        reg_key
      )

      file access_token_file do
        content access_token
        mode '0600'
        sensitive true
      end
    end
  end
end
