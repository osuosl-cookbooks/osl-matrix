# Synapse Server User
describe user('synapse') do
  it { should exist }
end

# Synapse Server

# Homeserver Directory
describe directory('/opt/synapse-chat.example.org') do
  it { should exist }
  its('owner') { should eq 'synapse' }
end

# Media_Store Directory
describe directory('/opt/synapse-chat.example.org/media_store') do
  it { should exist }
  its('owner') { should eq 'synapse' }
end

# Keys Directory
describe directory('/opt/synapse-chat.example.org/keys') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('mode') { should cmp '0700' }
end

# Homeserver Configuration
describe file('/opt/synapse-chat.example.org/homeserver.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('content') { should match 'server_name: chat.example.org' }
  its('content') { should match 'media_store_path: "/data/media_store"' }
  its('content') { should match '/data/appservice/osl-irc-bridge.yaml' }
  its('content') { should match '/data/appservice/osl-hookshot-webhook.yaml' }
  its('content') { should match 'module: ldap_auth_provider.LdapAuthProviderModule' }
  its('content') { should match 'name: psycopg2' }
end

# Docker Container
describe docker_container('synapse-synapse-1') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'matrixdotorg/synapse:latest' }
  its('ports') { should match '8008->8008/tcp' }
  its('ports') { should match '8448/tcp' }
end

# Check to see if we can send HTTP requests
describe http('localhost:8008/_matrix/client/versions', headers: { 'host': 'chat.example.org' }) do
  its('status') { should eq 200 }
end

# Heisenbridge Appservice

# Heisenbridge Appservice Configuration
describe file('/opt/synapse-chat.example.org/appservice/osl-irc-bridge.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('content') { should match 'id: heisenbridge' }
  its('content') { should match 'url: http://osl-irc-bridge:9898' }
end

# Docker Container
describe docker_container('synapse-osl-irc-bridge-1') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'hif1/heisenbridge:latest' }
end

# Hookshot Appservice

# Hookshot Appservice Configuration
describe file('/opt/synapse-chat.example.org/appservice/osl-hookshot-webhook.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('content') { should match 'id: hookshot' }
  its('content') { should match 'url: http://osl-hookshot-webhook:9993' }
end

describe file('/opt/synapse-chat.example.org/osl-hookshot-webhook-config.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('content') { should match 'generic:\n  enabled: true' }
end

# Hookshot Key
describe file('/opt/synapse-chat.example.org/keys/hookshot.pem') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('mode') { should cmp '0400' }
end

# Docker Container
describe docker_container('synapse-osl-hookshot-webhook-1') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'halfshot/matrix-hookshot:latest' }
  its('ports') { should match '9000-9002->9000-9002/tcp' }
end

# Matrix-Appservice-IRC Appservice

# Matrix-IRC Appservice Configuration
describe file('/opt/synapse-chat.example.org/appservice/osl-matrix-irc.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('content') { should match 'id: matrix-appservice-irc' }
  its('content') { should match 'url: http://osl-matrix-irc:8090' }
end

# Docker Container
describe docker_container('synapse-osl-matrix-irc-1') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'matrixdotorg/matrix-appservice-irc:latest' }
end

# Config File
describe file('/opt/synapse-chat.example.org/osl-matrix-irc-config.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('mode') { should cmp '0400' }
end

# IRC key
describe file('/opt/synapse-chat.example.org/keys/irc-passkey.pem') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('mode') { should cmp '0400' }
end

# Media signing key
describe file('/opt/synapse-chat.example.org/keys/signingkey.jwk') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('mode') { should cmp '0400' }
end

# Postgres data directory
describe file('/opt/synapse-chat.example.org/appservice-data/osl-matrix-irc-postgres/postgresql.conf') do
  it { should exist }
end

# Mjolnir Appservice

# Hookshot Appservice Configuration
describe file('/opt/synapse-chat.example.org/appservice/osl-moderate.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('content') { should match 'id: mjolnir' }
  its('content') { should match 'url: http://osl-moderate:9899' }
end

describe file('/opt/synapse-chat.example.org/osl-moderate-config.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
end

# Postgres data directory
describe file('/opt/synapse-chat.example.org/appservice-data/osl-moderate-db/postgresql.conf') do
  it { should exist }
end

# Main Docker Container
# Should not be running, as there is a default failing state.
describe docker_container('synapse-osl-moderate-1') do
  it { should exist }
  its('image') { should eq 'matrixdotorg/mjolnir:latest' }
end

# Database Docker Container
describe docker_container('synapse-osl-moderate-db-1') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'postgres' }
end
