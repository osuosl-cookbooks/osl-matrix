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
  its('content') { should match '/data/appservice/heisenbridge.yaml' }
  its('content') { should match '/data/appservice/hookshot.yaml' }
  its('content') { should match 'module: ldap_auth_provider.LdapAuthProviderModule' }
  its('content') { should match 'database: "/data/homeserver-sqlite.db"' }
end

# Docker Container
describe docker_container('e5af17-synapse-1') do
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
describe file('/opt/synapse-chat.example.org/appservice/heisenbridge.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('content') { should match 'id: heisenbridge' }
  its('content') { should match 'url: http://heisenbridge:9898' }
end

# Docker Container
describe docker_container('e5af17-heisenbridge-1') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'hif1/heisenbridge:latest' }
end

# Hookshot Appservice

# Hookshot Appservice Configuration
describe file('/opt/synapse-chat.example.org/appservice/hookshot.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('content') { should match 'id: hookshot' }
  its('content') { should match 'url: http://hookshot:9993' }
end

describe file('/opt/synapse-chat.example.org/hookshot-config.yaml') do
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
describe docker_container('e5af17-hookshot-1') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'halfshot/matrix-hookshot:latest' }
  its('ports') { should match '9000-9002->9000-9002/tcp' }
end

# Matrix-Appservice-IRC Appservice

# Matrix-IRC Appservice Configuration
describe file('/opt/synapse-chat.example.org/appservice/matrix-appservice-irc.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('content') { should match 'id: matrix-appservice-irc' }
  its('content') { should match 'url: http://matrix-appservice-irc:8090' }
end

# Docker Container
describe docker_container('e5af17-matrix-appservice-irc-1') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'matrixdotorg/matrix-appservice-irc:latest' }
end

# Config File
describe file('/opt/synapse-chat.example.org/matrix-appservice-irc-config.yaml') do
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
describe file('/opt/synapse-chat.example.org/appservice-data/matrix-appservice-irc-postgres/postgresql.conf') do
  it { should exist }
end

# Mjolnir Appservice

# Hookshot Appservice Configuration
describe file('/opt/synapse-chat.example.org/appservice/mjolnir.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('content') { should match 'id: mjolnir' }
  its('content') { should match 'url: http://mjolnir:9899' }
end

describe file('/opt/synapse-chat.example.org/mjolnir-config.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
end

# Main Docker Container
# Should not be running, as there is a default failing state.
describe docker_container('e5af17-mjolnir-1') do
  it { should exist }
  its('image') { should eq 'matrixdotorg/mjolnir:latest' }
end

# Database Docker Container
describe docker_container('e5af17-mjolnir-db-1') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'postgres' }
end

describe command '/opt/synapse-chat.example.org/bin/docker_compose ps' do
  %w(
    heisenbridge
    hookshot
    matrix-appservice-irc
    mjolnir
    synapse
  ).each do |s|
    its('stdout') { should match s }
  end
end
