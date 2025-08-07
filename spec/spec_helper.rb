require 'chefspec'
require 'chefspec/berkshelf'

ALMA_8 = {
  platform: 'almalinux',
  version: '8',
}.freeze

ALMA_9 = {
  platform: 'almalinux',
  version: '9',
}.freeze

ALL_PLATFORMS = [
  ALMA_8,
  ALMA_9,
].freeze

RSpec.configure do |config|
  config.log_level = :warn
end

RSpec.shared_context 'pwnam' do
  # Stub the command to find the user 'synapse's UID.
  before do
    allow(Etc).to receive(:getpwnam).and_return(
      Etc::Passwd.new(
        'synapse',
        nil,
        1001,
        nil,
        nil,
        nil
      )
    )
  end
end

require_relative '../libraries/helpers'

shared_context 'common' do
  before do
    stub_command('iptables -C INPUT -j REJECT --reject-with icmp-host-prohibited 2>/dev/null').and_return(true)
    allow_any_instance_of(Chef::Provider).to receive(:channel_alias_exists?).and_return(false)
    allow_any_instance_of(Chef::Provider).to receive(:check_server_readiness).and_return(true)
    allow_any_instance_of(Chef::Provider).to receive(:create_channel).and_return(true)
    allow_any_instance_of(Chef::Provider).to receive(:create_or_update_user).and_return(true)
    allow_any_instance_of(Chef::Provider).to receive(:get_user_details).and_return(nil)
    allow_any_instance_of(Chef::Provider).to receive(:login_as_user).and_return('login_as_user_access_token')
    allow_any_instance_of(Chef::Provider).to receive(:register_initial_admin).and_return('admin_access_token')
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with('/opt/synapse-chat.example.org/keys/mjolnir-access_token.key').and_return('mjolnir_access_token')
    allow(File).to receive(:read).with('/opt/synapse-chat.example.org/keys/admin-access_token.key').and_return('admin_access_token')
    allow(File).to receive(:read).with('/opt/synapse-chat.example.org/keys/registration.key').and_return('registration.key')
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/opt/synapse-chat.example.org/keys/mjolnir-access_token.key').and_return(false)
  end
end
