%w(test_admin test_multiple_servers).each_with_index do |container, idx|
  # Webapp container
  describe docker_container(container) do
    it { should exist }
    it { should be_running }
    its('image') { should eq 'awesometechnologies/synapse-admin:latest' }
    its('ports') { should match "0.0.0.0:#{8080 + idx}->80/tcp" }
  end

  # Site's config
  describe directory('/opt/synapse_admin_test_admin') do
    it { should exist }
  end

  # Website
  describe port(8080 + idx) do
    it { should be_listening }
    its('protocols') { should include 'tcp' }
  end

  describe http("127.0.0.1:#{8080 + idx}") do
    its('status') { should eq 200 }
    its('body') { should match '<title>Synapse-Admin</title>' }
  end
end

describe file('/opt/synapse_admin_test_admin/config.json') do
  it { should exist }
  its('content') { should match '"restrictBaseUrl":"https://chat.example.org"' }
end

describe file('/opt/synapse_admin_test_multiple_servers/config.json') do
  it { should exist }
  its('content') { should match '{"restrictBaseUrl":["https://chat.example.org","https://ops.example.org","https://osuosl.example.org"]}' }
end
