# Create a quick synapse server
osl_synapse_service 'chat.example.org' do
  appservices %w(hookshot heisenbridge)
  reg_key 'this-is-my-secret'
  config(
    {
      'modules' => [
        {
          'module' => 'ldap_auth_provider.LdapAuthProviderModule',
          'config' => {
            'enabled' => true,
            'uri' => 'ldap://ldap.osuosl.org:389',
            'start_tls' => true,
            'base' => 'ou=People,dc=osuosl,dc=org',
            'attributes' => {
              'uid' => 'uid',
              'mail' => 'mail',
              'name' => 'givenName',
            },
          },
        },
      ],
    }
  )
  config_hookshot(
    {
      'generic' => {
        'enabled' => true,
        'urlPrefix' => 'http://chat.example.org/webhook',
        'userIdPrefix' => 'example-hook',
      },
    }
  )
end

chef_sleep 'Waiting for iptables to restart' do
  seconds 10
  action :nothing
  subscribes :sleep, 'osl_synapse_service[chat.example.org]'
end

# Make one more synapse server, which is synapse by itself
osl_synapse_service 'anotherchat.example.org' do
  reg_key 'another-secret-for-you'
  port 8009
  fed_port 8449
end
