# Create a quick synapse server
osl_synapse_quick 'chat.example.org' do
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
