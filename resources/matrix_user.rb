# osl_matrix_user
#
# Register a new matrix user, and login
# Saves credentials in /root

resource_name :osl_matrix_user
provides :osl_matrix_user
unified_mode true

default_action :register

property :username, String, name_property: true
property :password, String, required: true
property :admin, [true, false], default: false
property :domain, String, required: true
property :homeserver_url, String, default: 'http://localhost:8008'

action :register do
  if ::File.exist?("/root/#{new_resource.username}-access-token.txt")
    return
  end

  # https://element-hq.github.io/synapse/latest/admin_api/register_api.html#shared-secret-registration
  # Create registration request body
  register_body = {
    'username': new_resource.username,
    'password': new_resource.password,
    'admin': new_resource.admin,
  }
  # Get nonce from request
  response = Net::HTTP.get(URI("#{new_resource.homeserver_url}/_synapse/admin/v1/register"))
  parsed_response = JSON.parse(response)

  log 'Unable to interact with Synapse server' do
    level :error
    not_if { parsed_response.key?('nonce') }
  end

  nonce = parsed_response['nonce']

  # Send registration request
  # Get shared key
  shared_key = ::File.read("/opt/synapse-#{new_resource.domain}/keys/registration.key")
  hmac_digest = OpenSSL::HMAC.hexdigest(
    'sha1',
    shared_key,
    (
      "#{nonce}\0" \
      "#{new_resource.username}\0" \
      "#{new_resource.password}\0" \
      "#{new_resource.admin ? 'admin' : 'notadmin'}"
    ).encode('utf-8')
  )

  # Add in the rest of the request body
  register_body['nonce'] = nonce
  register_body['mac'] = hmac_digest

  response = Net::HTTP.post(
    URI("#{new_resource.homeserver_url}/_synapse/admin/v1/register"),
    register_body.to_json,
    { 'Content-Type': 'application/json' }
  )
  parsed_response = JSON.parse(response.body)

  # Raise error if it fails

  log 'Unable to register user' do
    level :error
    not_if { parsed_response.key?('user_id') }
  end

  # Save login credentials
  file "/root/#{new_resource.username}-access-token.txt" do
    content parsed_response['access_token']
    mode '003'
  end
end
