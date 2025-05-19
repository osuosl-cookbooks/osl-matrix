# Element container
describe docker_container('element_webapp') do
  it { should exist }
  it { should be_running }
  its('image') { should eq 'vectorim/element-web:latest' }
  its('ports') { should match '0.0.0.0:8000->80/tcp' }
end

# Site's config

describe directory('/opt/element') do
  it { should exist }
end

describe file('/opt/element/config.json') do
  it { should exist }
  its('content') { should match '"base_url": "https://chat.example.org"' }
  its('content') { should match '"welcome_background_url": "/assets/background.jpg"' }
  its('content') { should match '"auth_header_logo_url": "/assets/logo.svg"' }
end

# Website
describe port(8000) do
  it { should be_listening }
  its('protocols') { should include 'tcp' }
end

describe http('127.0.0.1:8000', headers: { 'Host': 'chat.example.org' }) do
  its('status') { should eq 200 }
  its('body') { should match '<title>Element</title>' }
end

# Branding

%w(background.jpg logo.svg).each do |f|
  describe http("127.0.0.1:8000/assets/#{f}", headers: { 'Host': 'chat.example.org' }) do
    its('status') { should eq 200 }
  end
end
