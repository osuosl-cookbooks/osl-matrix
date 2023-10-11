# Synapse Server User
describe user('synapse') do
  it { should exist }
end

# Synapse Server File Structure
describe directory('/opt/synapse-chat.example.org') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('mode') { should eq '750' }
end

describe directory('/opt/synapse-chat.example.org/keys') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('mode') { should eq '700' }
end

describe file('/opt/synapse-chat.example.org/keys/registration.key') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('mode') { should eq '400' }
end

describe file('/opt/synapse-chat.example.org/homeserver.yaml') do
  it { should exist }
  its('owner') { should eq 'synapse' }
  its('mode') { should eq '600' }
end
