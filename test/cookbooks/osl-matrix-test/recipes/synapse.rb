include_recipe 'osl-docker'

# Add on the Heisenbridge app service
osl_heisenbridge 'osl-irc-bridge'

# Create the synapse docker container
osl_matrix 'chat.osuosl.intnet' do
  use_sqlite true
  app_services ['osl-irc-bridge']
  config <<~EOF
modules:
  - module: "ldap_auth_provider.LdapAuthProviderModule"
    config:
      enabled: true
      uri: "ldap://ldap.osuosl.org:389"
      start_tls: true
      base: "ou=People,dc=osuosl,dc=org"
      attributes:
        uid: "uid"
        mail: "mail"
        name: "givenName"
  EOF
end
