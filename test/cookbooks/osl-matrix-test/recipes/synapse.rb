append_if_no_line node['ipaddress'] do
  path '/etc/hosts'
  line "#{node['ipaddress']} chat.example.org"
  sensitive false
end

# Create a quick synapse server
osl_synapse_service 'chat.example.org' do
  admin_password 'admin'
  appservices %w(hookshot heisenbridge matrix-appservice-irc mjolnir)
  reg_key 'this-is-my-secret'
  mjolnir_password 'mjolnir'
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
        'userIdPrefix' => 'example-hook_',
      },
    }
  )
  config_matrix_irc({
    'ircService' => {
      'servers' => {
        'ircd' => {},
      },
    },
  })
end

osl_matrix_user 'test' do
  password 'test'
  homeserver_url 'http://chat.example.org:8008'
end
