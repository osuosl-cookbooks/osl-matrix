{ 'test_admin' => 'v1', 'test_multiple_servers' => 'v1', 'test_pinned' => 'v1.5.2' }.each_with_index do |(container, tag), idx|
  # Webapp container
  describe docker_container(container) do
    it { should exist }
    it { should be_running }
    its('image') { should eq "etkecc/ketesa:#{tag}" }
    its('ports') { should match "0.0.0.0:#{8080 + idx}->8080/tcp" }
  end

  # Site's config
  describe directory("/opt/synapse_admin_#{container}") do
    it { should exist }
  end

  # Website
  describe port(8080 + idx) do
    it { should be_listening }
    its('protocols') { should include 'tcp' }
  end

  describe http("127.0.0.1:#{8080 + idx}") do
    its('status') { should eq 200 }
    its('body') { should match '<title>Ketesa</title>' }
  end

  # The image ships an empty config.json, so restrictBaseUrl here proves the bind mount
  describe http("127.0.0.1:#{8080 + idx}/config.json") do
    its('status') { should eq 200 }
    its('body') { should match '"restrictBaseUrl"' }
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

describe http('127.0.0.1:8082/config.json') do
  its('body') { should match '"asManagedUsers":\["\^@bot:example.org\$"\]' }
end
