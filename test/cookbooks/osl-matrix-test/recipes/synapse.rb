# Create the synapse docker container
osl_synapse 'chat.example.org' do
  app_services %w(osl-irc-bridge)
  use_sqlite true
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
