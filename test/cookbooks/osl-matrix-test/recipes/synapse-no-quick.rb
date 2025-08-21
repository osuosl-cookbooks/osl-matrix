append_if_no_line node['ipaddress'] do
  path '/etc/hosts'
  line "#{node['ipaddress']} chat.example.org"
  sensitive false
end

include_recipe 'osl-docker'

osl_postgresql_server 'default' do
  access 'access'
  databases 'databases'
  users 'users'
  osl_only false
  action [:create, :start]
end

# Create the synapse docker container
osl_synapse 'chat.example.org' do
  appservices %w(osl-irc-bridge osl-hookshot-webhook osl-matrix-irc osl-moderate)
  reg_key 'this-is-my-secret'
  pg_host node['ipaddress']
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

osl_matrix_admin_user 'admin' do
  password 'admin'
  domain 'chat.example.org'
  homeserver_url 'http://localhost:8008'
end

osl_matrix_user 'mjolnir' do
  password 'mjolnir'
  admin true
  domain 'chat.example.org'
  homeserver_url 'http://localhost:8008'
  action [:create, :token]
end

osl_matrix_channel 'mjolnir' do
  display_name 'mjolnir'
  domain 'chat.example.org'
  homeserver_url 'http://localhost:8008'
  user 'mjolnir'
end

# Mjolnir moderation
osl_mjolnir 'osl-moderate' do
  host_domain 'chat.example.org'
  notifies :rebuild, 'osl_dockercompose[synapse]'
  notifies :restart, 'osl_dockercompose[synapse]'
  notifies :create, 'osl_synapse[chat.example.org]'
  notifies :restart, 'osl_synapse[chat.example.org]'
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
  notifies :rebuild, 'osl_dockercompose[synapse]'
  notifies :restart, 'osl_dockercompose[synapse]'
  notifies :create, 'osl_synapse[chat.example.org]'
  notifies :restart, 'osl_synapse[chat.example.org]'
end

# Add on the Heisenbridge app service
osl_heisenbridge 'osl-irc-bridge' do
  host_domain 'chat.example.org'
  notifies :rebuild, 'osl_dockercompose[synapse]'
  notifies :restart, 'osl_dockercompose[synapse]'
  notifies :create, 'osl_synapse[chat.example.org]'
  notifies :restart, 'osl_synapse[chat.example.org]'
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
  notifies :rebuild, 'osl_dockercompose[synapse]'
  notifies :restart, 'osl_dockercompose[synapse]'
  notifies :create, 'osl_synapse[chat.example.org]'
  notifies :restart, 'osl_synapse[chat.example.org]'
end
#
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
  notifies :rebuild, 'osl_dockercompose[synapse]'
  notifies :restart, 'osl_dockercompose[synapse]'
  notifies :create, 'osl_synapse[chat.example.org]'
  notifies :restart, 'osl_synapse[chat.example.org]'
end

# Run the docker compose
osl_dockercompose 'synapse' do
  directory '/opt/synapse-chat.example.org/compose'
  config_files %w(
    docker-addons.yaml
    docker-osl-irc-bridge.yaml
    docker-osl-hookshot-webhook.yaml
    docker-osl-matrix-irc.yaml
    docker-osl-moderate.yaml
  )
end
