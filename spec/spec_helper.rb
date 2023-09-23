require 'chefspec'
require 'chefspec/berkshelf'

ALMALINUX_8 = {
  platform: 'almalinux',
  version: '8',
}.freeze

CENTOS_8 = {
  platform: 'centos',
  version: '8',
}.freeze

ALL_PLATFORMS = [
  ALMALINUX_8,
  CENTOS_8,
].freeze

RSpec.configure do |config|
  config.log_level = :warn
end
