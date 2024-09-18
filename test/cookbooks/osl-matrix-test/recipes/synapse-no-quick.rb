include_recipe 'osl-docker'

# Create the synapse docker container
osl_synapse 'chat.example.org' do
  appservices %w(osl-irc-bridge osl-hookshot-webhook osl-matrix-irc)
  reg_key 'this-is-my-secret'
  pg_host 'postgres'
  pg_name 'synapse'
  pg_username 'synapse'
  pg_password 'password'
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
  sensitive false
end

# Matrix-Appservice-IRC App Service
osl_matrix_irc 'osl-matrix-irc' do
  host_domain 'chat.example.org'
  config({
    'ircService' => {
      'servers' => {
        'ircd' => {},
      },
    },
  })
  sensitive false
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

# Additional servers for testing
file '/opt/synapse-chat.example.org/compose/docker-addons.yaml' do
  content osl_yaml_dump({
    'services' => {
      'postgres' => {
        'image' => 'postgres',
        'environment' => {
          'POSTGRES_PASSWORD' => 'password',
          'POSTGRES_USER' => 'synapse',
          'POSTGRES_INITDB_ARGS' => '--encoding=UTF8 --locale=C',
        },
      },
      'ircd' => {
        'image' => 'inspircd/inspircd-docker',
      },
    },
  })
  owner 'synapse'
  group 'synapse'
  mode '400'
end

# Run the docker compose
osl_dockercompose 'synapse' do
  directory '/opt/synapse-chat.example.org/compose'
  config %w(docker-addons.yaml docker-synapse.yaml docker-osl-irc-bridge.yaml docker-osl-hookshot-webhook.yaml docker-osl-matrix-irc.yaml)
end
