# Create the synapse docker container
osl_synapse 'chat.example.org' do
  app_services %w(osl-irc-bridge osl-hookshot-webhook)
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
end

# Add on the Heisenbridge app service
osl_heisenbridge 'osl-irc-bridge' do
  host_domain 'chat.example.org'
end

# Add on the Hookshot app service
osl_hookshot 'osl-hookshot-webhook' do
  host_domain 'chat.example.org'
  config({
    'permissions' => [
      {
        'actor' => 'chat.example.org',
        'services' => [
          {
            'service' => '*',
            'level' => 'admin',
          },
        ],
      },
    ],
    'generic' => {
      'enabled' => true,
      'urlPrefix' => 'http://chat.example.org/webhook',
      'userIdPrefix' => 'my-amazing-hook_',
    },
  })
end
