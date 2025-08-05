#
# Cookbook:: osl-matrix
# Spec:: osl_synapse, osl_heisenbridge, osl_hookshot
#
# Copyright:: 2023-2025, Oregon State University
#

require_relative '../../spec_helper'

# osl_synapse
describe 'osl-matrix-test::synapse-no-quick' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge({ step_into: :osl_synapse })).converge(described_recipe)
      end
      include_context 'pwnam'
      include_context 'common'

      # Create the user who will be managing the synapse instances
      it { is_expected.to create_user('synapse').with(system: true) }

      # Synapse instance directory
      it do
        is_expected.to create_directory('/opt/synapse-chat.example.org').with(
          owner: 'synapse',
          mode: '750'
        )
      end

      # Synapse instance's more confidential directories: keys, appservice, and compose
      it do
        %w(appservice compose keys).each do |dir|
          is_expected.to create_directory("/opt/synapse-chat.example.org/#{dir}").with(
            owner: 'synapse',
            mode: '700'
          )
        end
      end

      # Matrix instance's secret key
      it do
        is_expected.to create_if_missing_file('/opt/synapse-chat.example.org/keys/registration.key').with(
          content: 'this-is-my-secret',
          owner: 'synapse',
          mode: '400',
          sensitive: true
        )
      end

      # Generate the Homeserver config
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/homeserver.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end

      # Create the Synapse compose file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-synapse.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end
    end
  end
end

# osl_heisenbridge
describe 'osl-matrix-test::synapse-no-quick' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge({ step_into: :osl_heisenbridge })).converge(described_recipe)
      end
      include_context 'pwnam'
      include_context 'common'

      # Appservice file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/appservice/osl-irc-bridge.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end

      # Create the Heisenbridge compose file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-osl-irc-bridge.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end
    end
  end
end

# osl_hookshot
describe 'osl-matrix-test::synapse-no-quick' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge({ step_into: :osl_hookshot })).converge(described_recipe)
      end
      include_context 'pwnam'
      include_context 'common'

      # Appservice file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/appservice/osl-hookshot-webhook.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end

      # Generate passkey file
      it do
        is_expected.to run_execute('Generating Hookshot Passkey').with(
          command: "openssl genpkey -out \"/opt/synapse-chat.example.org/keys/hookshot.pem\" -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096; chmod 400 '/opt/synapse-chat.example.org/keys/hookshot.pem'",
          user: 'synapse',
          group: 'synapse'
        )
      end

      # Generate config file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/osl-hookshot-webhook-config.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end

      # Create Hookshot compose file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-osl-hookshot-webhook.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end
    end
  end
end

# osl_matrix_irc
describe 'osl-matrix-test::synapse-no-quick' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge({ step_into: :osl_matrix_irc })).converge(described_recipe)
      end
      include_context 'pwnam'
      include_context 'common'

      # Appservice file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/appservice/osl-matrix-irc.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end

      # Generate passkey file
      it do
        is_expected.to run_execute('Generating Matrix-Appservice-IRC Passkey').with(
          command: "openssl genpkey -out \"/opt/synapse-chat.example.org/keys/irc-passkey.pem\" -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:2048; chmod 400 '/opt/synapse-chat.example.org/keys/irc-passkey.pem'",
          user: 'synapse',
          group: 'synapse'
        )
      end

      # Generate signing key file
      it do
        is_expected.to run_execute('Generate signingkey').with(
          command: 'docker run --rm --entrypoint "sh" --volume /opt/synapse-chat.example.org/keys:/data --user 1001: matrixdotorg/matrix-appservice-irc "-c" "node lib/generate-signing-key.js > /data/signingkey.jwk && chmod 400 /data/signingkey.jwk"'
        )
      end

      # Generate config file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/osl-matrix-irc-config.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end

      # Create matrix-appservice-irc compose file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-osl-matrix-irc.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end
    end
  end
end

# osl_mjolnir
describe 'osl-matrix-test::synapse-no-quick' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge({ step_into: :osl_mjolnir })).converge(described_recipe)
      end
      include_context 'pwnam'
      include_context 'common'

      # Appservice file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/appservice/osl-moderate.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end

      # Generate config file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/osl-moderate-config.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end

      # Create Hookshot compose file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-osl-moderate.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true
        )
      end
    end
  end
end
