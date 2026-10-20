require_relative '../../spec_helper'

describe OSLMatrix::Cookbook::Helpers do
  subject(:helper) { Class.new { include OSLMatrix::Cookbook::Helpers }.new }

  it 'omits a nil topic from the createRoom body' do
    expect(helper).to receive(:perform_request) do |_uri, **kwargs|
      expect(kwargs[:body]).not_to have_key(:topic)
      Net::HTTPOK.new('1.1', '200', 'OK')
    end
    helper.create_channel('http://localhost:8008', 'tok', 'mjolnir', 'mjolnir', nil, false)
  end

  it 'keeps a topic that is set' do
    expect(helper).to receive(:perform_request) do |_uri, **kwargs|
      expect(kwargs[:body]).to include(topic: 'Moderation')
      Net::HTTPOK.new('1.1', '200', 'OK')
    end
    helper.create_channel('http://localhost:8008', 'tok', 'mjolnir', 'mjolnir', 'Moderation', false)
  end
end
