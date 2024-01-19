#
# Cookbook:: osl-matrix
# Spec:: osl_synapse, osl_heisenbridge, osl_hookshot
#
# Copyright:: 2023-2024, Oregon State University
#

require_relative '../../spec_helper'

# osl_synapse
describe 'osl-matrix-test::synapse' do
  cached(:subject) { chef_run }
  platform 'almalinux', '8'
  include_context 'pwnam'
  step_into :osl_synapse

  # Create the user who will be managing the synapse instances
  it { is_expected.to create_user('synapse').with(system: true) }

  # Synapse instance directory
  it {
    is_expected.to create_directory('/opt/synapse-matrix-synapse-chat.example.org').with(
      owner: 'synapse',
      mode: '750'
    )
  }

  # Synapse instance's keys directory, more confidential
  it {
    is_expected.to create_directory('/opt/synapse-matrix-synapse-chat.example.org').with(
      owner: 'synapse',
      mode: '750'
    )
  }

  # Docker network for this synapse instance's ecosystem.
  it { is_expected.to create_docker_network('synapse-network-matrix-synapse-chat.example.org') }

  # Matrix instance's secret key
  it {
    is_expected.to create_if_missing_file('/opt/synapse-matrix-synapse-chat.example.org/keys/registration.key').with(
      content: 'this-is-my-secret',
      owner: 'synapse',
      mode: '400',
      sensitive: true
    )
  }

  # Generate the Homeserver config
  it {
    is_expected.to create_file('/opt/synapse-matrix-synapse-chat.example.org/homeserver.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }

  # Pull down the image
  it { is_expected.to pull_docker_image('matrixdotorg/synapse') }

  # Create the Synapse container
  it {
    is_expected.to run_docker_container('matrix-synapse-chat.example.org').with(
      repo: 'matrixdotorg/synapse',
      port: %w(8008:8008 8448:8448),
      user: '1001:',
      restart_policy: 'always'
    )
  }

  # Connect the synapse container to the network ecosystem
  it {
    is_expected.to connect_docker_network('synapse-network-matrix-synapse-chat.example.org').with(
      container: 'matrix-synapse-chat.example.org'
    )
  }
end

# osl_heisenbridge
describe 'osl-matrix-test::synapse' do
  cached(:subject) { chef_run }
  platform 'almalinux', '8'
  include_context 'pwnam'
  step_into :osl_heisenbridge

  # Appservice file
  it {
    is_expected.to create_file('/opt/synapse-matrix-synapse-chat.example.org/osl-irc-bridge.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }

  # Pull down the heisenbridge image
  it { is_expected.to pull_docker_image('hif1/heisenbridge') }

  # Create the Docker Container
  it {
    is_expected.to run_docker_container('osl-irc-bridge').with(
      repo: 'hif1/heisenbridge',
      user: '1001:',
      entrypoint: %w(python -m heisenbridge -c /data/osl-irc-bridge.yaml http://matrix-synapse-chat.example.org:8008),
      restart_policy: 'always'
    )
  }

  # Connect to the Docker Network
  it {
    is_expected.to connect_docker_network('synapse-network-matrix-synapse-chat.example.org').with(
      container: 'osl-irc-bridge'
    )
  }
end

describe 'osl-matrix-test::synapse' do
  cached(:subject) { chef_run }
  platform 'almalinux', '8'
  include_context 'pwnam'
  step_into :osl_hookshot

  # Appservice file
  it {
    is_expected.to create_file('/opt/synapse-matrix-synapse-chat.example.org/osl-hookshot-webhook.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }

  # Generate passkey file
  it {
    is_expected.to run_execute('Generating Hookshot Passkey').with(
      command: "openssl genpkey -out \"/opt/synapse-matrix-synapse-chat.example.org/keys/hookshot.pem\" -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096; chmod 400 '/opt/synapse-matrix-synapse-chat.example.org/keys/hookshot.pem'",
      user: 'synapse',
      group: 'synapse'
    )
  }

  # Generate config file
  it {
    is_expected.to create_file('/opt/synapse-matrix-synapse-chat.example.org/osl-hookshot-webhook-config.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }

  # Pull down the hookshot image
  it { is_expected.to pull_docker_image('halfshot/matrix-hookshot') }

  # Create docker container
  it {
    is_expected.to run_docker_container('osl-hookshot-webhook').with(
      repo: 'halfshot/matrix-hookshot',
      user: '1001:',
      port: %w(9000:9000 9001:9001 9002:9002),
      restart_policy: 'always'
    )
  }

  # Connect to the Docker Network
  it {
    is_expected.to connect_docker_network('synapse-network-matrix-synapse-chat.example.org').with(
      container: 'osl-hookshot-webhook'
    )
  }
end
