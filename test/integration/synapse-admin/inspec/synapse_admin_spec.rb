# Webapp container
describe docker_container('synapse_admin_webapp') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'awesometechnologies/synapse-admin:latest' }
  its('ports') { should match '0.0.0.0:8080->80/tcp' }
end

# Site's config

describe directory('/opt/synapse_admin') do
  it { should exist }
end

describe file('/opt/synapse_admin/config.json') do
  it { should exist }
  its('content') { should match '"restrictBaseUrl":"chat.example.org"' }
end

# Website
describe port(8080) do
  it { should be_listening }
  its('protocols') { should include 'tcp' }
end

describe http('127.0.0.1:8080') do
  its('status') { should eq 200 }
  its('body') { should match '<title>Synapse-Admin</title>' }
end
