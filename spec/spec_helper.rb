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

shared_context 'common' do
  before do
    stub_command('iptables -C INPUT -j REJECT --reject-with icmp-host-prohibited 2>/dev/null').and_return(true)
  end
end
