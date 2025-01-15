#
# Cookbook:: osl-matrix
# Spec:: osl_synapse, osl_heisenbridge, osl_hookshot
#
# Copyright:: 2023-2025, Oregon State University
#

require_relative '../../spec_helper'

# osl_synapse
describe 'osl-matrix-test::synapse-no-quick' do
  cached(:subject) { chef_run }
  platform 'almalinux', '8'
  include_context 'pwnam'
  step_into :osl_synapse

  # Create the user who will be managing the synapse instances
  it { is_expected.to create_user('synapse').with(system: true) }

  # Synapse instance directory
  it {
    is_expected.to create_directory('/opt/synapse-chat.example.org').with(
      owner: 'synapse',
      mode: '750'
    )
  }

  # Synapse instance's more confidential directories: keys, appservice, and compose
  it {
    %w(appservice compose keys).each do |dir|
      is_expected.to create_directory("/opt/synapse-chat.example.org/#{dir}").with(
        owner: 'synapse',
        mode: '700'
      )
    end
  }

  # Matrix instance's secret key
  it {
    is_expected.to create_if_missing_file('/opt/synapse-chat.example.org/keys/registration.key').with(
      content: 'this-is-my-secret',
      owner: 'synapse',
      mode: '400',
      sensitive: true
    )
  }

  # Generate the Homeserver config
  it {
    is_expected.to create_file('/opt/synapse-chat.example.org/homeserver.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }

  # Create the Synapse compose file
  it {
    is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-synapse.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }
end

# osl_heisenbridge
describe 'osl-matrix-test::synapse-no-quick' do
  cached(:subject) { chef_run }
  platform 'almalinux', '8'
  include_context 'pwnam'
  step_into :osl_heisenbridge

  # Appservice file
  it {
    is_expected.to create_file('/opt/synapse-chat.example.org/appservice/osl-irc-bridge.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }

  # Create the Heisenbridge compose file
  it {
    is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-osl-irc-bridge.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }
end

# osl_hookshot
describe 'osl-matrix-test::synapse-no-quick' do
  cached(:subject) { chef_run }
  platform 'almalinux', '8'
  include_context 'pwnam'
  step_into :osl_hookshot

  # Appservice file
  it {
    is_expected.to create_file('/opt/synapse-chat.example.org/appservice/osl-hookshot-webhook.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }

  # Generate passkey file
  it {
    is_expected.to run_execute('Generating Hookshot Passkey').with(
      command: "openssl genpkey -out \"/opt/synapse-chat.example.org/keys/hookshot.pem\" -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096; chmod 400 '/opt/synapse-chat.example.org/keys/hookshot.pem'",
      user: 'synapse',
      group: 'synapse'
    )
  }

  # Generate config file
  it {
    is_expected.to create_file('/opt/synapse-chat.example.org/osl-hookshot-webhook-config.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }

  # Create Hookshot compose file
  it {
    is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-osl-hookshot-webhook.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }
end

# osl_matrix_irc
describe 'osl-matrix-test::synapse-no-quick' do
  cached(:subject) { chef_run }
  platform 'almalinux', '8'
  include_context 'pwnam'
  step_into :osl_matrix_irc

  # Appservice file
  it {
    is_expected.to create_file('/opt/synapse-chat.example.org/appservice/osl-matrix-irc.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }

  # Generate passkey file
  it {
    is_expected.to run_execute('Generating Matrix-Appservice-IRC Passkey').with(
      command: "openssl genpkey -out \"/opt/synapse-chat.example.org/keys/irc-passkey.pem\" -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:2048; chmod 400 '/opt/synapse-chat.example.org/keys/irc-passkey.pem'",
      user: 'synapse',
      group: 'synapse'
    )
  }

  # Generate signing key file
  it {
    is_expected.to run_execute('Generate signingkey').with(
      command: 'docker run --rm --entrypoint "sh" --volume /opt/synapse-chat.example.org/keys:/data --user 1001: matrixdotorg/matrix-appservice-irc "-c" "node lib/generate-signing-key.js > /data/signingkey.jwk && chmod 400 /data/signingkey.jwk"'
    )
  }

  # Generate config file
  it {
    is_expected.to create_file('/opt/synapse-chat.example.org/osl-matrix-irc-config.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }

  # Create matrix-appservice-irc compose file
  it {
    is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-osl-matrix-irc.yaml').with(
      owner: 'synapse',
      group: 'synapse',
      mode: '400',
      sensitive: true
    )
  }
end
