require 'chefspec'
require 'chefspec/berkshelf'

RSpec.configure do |config|
  config.log_level = :warn
end

RSpec.shared_context 'pwnam' do
  # Stub the command to find the user 'synapse's UID.
  before do
    allow(Etc).to receive(:getpwnam).and_return(
      Etc::Passwd.new(
        nil,
        nil,
        1001,
        nil,
        nil,
        nil
      )
    )
  end
end
