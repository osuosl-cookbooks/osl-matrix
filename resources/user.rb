resource_name :osl_matrix_user
provides :osl_matrix_user
unified_mode true

property :admin, [true, false], default: false
property :domain, String, default: lazy { URI.parse(homeserver_url).host }
property :homeserver_url, String, required: true
property :password, String, required: true, sensitive: true
property :retries, Integer, default: 10
property :retry_delay, Integer, default: 20
property :username, String, name_property: true

default_action :create

action :create do
  check_server_readiness(new_resource.homeserver_url)

  access_token = ::File.read("/opt/synapse-#{new_resource.domain}/keys/admin-access_token.key")
  mxid = "@#{new_resource.username}:#{new_resource.domain}"
  user_api_url = "#{new_resource.homeserver_url}/_synapse/admin/v2/users/#{URI.encode_www_form_component(mxid)}"
  auth_header = "Bearer #{access_token}"

  # This returns user data hash or nil if user does not exist
  current_user = get_user_details(user_api_url, auth_header)
  current_admin_status = current_user ? current_user.fetch('admin', false) : nil

  if current_user.nil?
    # User does not exist, so create them
    converge_by("create new matrix user #{mxid}") do
      create_payload = {
        password: new_resource.password,
        displayname: new_resource.username,
        admin: new_resource.admin,
      }
      create_or_update_user(user_api_url, auth_header, create_payload)
      Chef::Log.info("Successfully created user #{mxid}.")
    end
  elsif current_admin_status != new_resource.admin
    # User exists, but admin status is incorrect
    converge_by("update admin status for user #{mxid} to #{new_resource.admin}") do
      update_payload = { admin: new_resource.admin }
      create_or_update_user(user_api_url, auth_header, update_payload)
      Chef::Log.info("Successfully updated admin status for #{mxid}.")
    end
  else
    # User exists with correct state, do nothing
    Chef::Log.info("User #{mxid} already exists with the correct admin status. Nothing to do.")
  end
end

action :token do
  check_server_readiness(new_resource.homeserver_url)
  access_token = ::File.read("/opt/synapse-#{new_resource.domain}/keys/admin-access_token.key")
  user_token_file = "/opt/synapse-#{new_resource.domain}/keys/#{new_resource.username}-access_token.key"
  mxid = "@#{new_resource.username}:#{new_resource.domain}"

  unless ::File.exist?(user_token_file)
    converge_by "registering token for #{new_resource.username}" do
      token = login_as_user(new_resource.homeserver_url, access_token, mxid, device_id: 'Chef-Login')

      file user_token_file do
        content token
        mode '0600'
        sensitive true
      end
    end
  end
end
