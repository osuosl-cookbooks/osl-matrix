#
# Cookbook:: osl-matrix
# Spec:: osl_synapse, osl_heisenbridge, osl_hookshot
#
# Copyright:: 2023-2025, Oregon State University
#

require_relative '../../spec_helper'

describe 'osl-matrix-test::synapse' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge({
          step_into: %w(
            osl_synapse_service
          ),
        })).converge(described_recipe)
      end

      include_context 'pwnam'
      include_context 'common'

      it 'converges successfully' do
        expect { chef_run }.to_not raise_error
      end

      it do
        is_expected.to nothing_osl_dockercompose('synapse_service_chat_example_org').with(
          directory: '/opt/synapse-chat.example.org/compose',
          config_files: %w(
            docker-hookshot.yaml
            docker-heisenbridge.yaml
            docker-matrix-appservice-irc.yaml
            docker-mjolnir.yaml
          )
        )
      end

      it do
        is_expected.to create_osl_synapse('chat.example.org').with(
          appservices: %w(hookshot heisenbridge matrix-appservice-irc mjolnir),
          config: {
            'modules' => [
              {
                'module' => 'ldap_auth_provider.LdapAuthProviderModule',
                'config' => {
                  'enabled' => true,
                  'uri' => 'ldap://ldap.osuosl.org:389',
                  'start_tls' => true,
                  'base' => 'ou=People,dc=osuosl,dc=org',
                  'attributes' => {
                    'uid' => 'uid',
                    'mail' => 'mail',
                    'name' => 'givenName',
                  },
                },
              },
            ],
          },
          pg_host: nil,
          pg_name: nil,
          pg_username: nil,
          pg_password: nil,
          port: 8008,
          fed_port: 8448,
          reg_key: 'this-is-my-secret',
          tag: 'latest'
        )
      end

      it do
        is_expected.to create_osl_matrix_admin_user('admin').with(
          password: 'admin',
          domain: 'chat.example.org',
          homeserver_url: 'http://localhost:8008'
        )
      end

      it do
        is_expected.to create_osl_heisenbridge('heisenbridge').with(
          host_domain: 'chat.example.org',
          tag: 'latest'
        )
      end

      it do
        expect(chef_run.osl_heisenbridge('heisenbridge')).to \
          notify('osl_dockercompose[synapse_service_chat_example_org]').to(:rebuild)
      end

      it do
        expect(chef_run.osl_heisenbridge('heisenbridge')).to \
          notify('osl_dockercompose[synapse_service_chat_example_org]').to(:restart)
      end

      it do
        expect(chef_run.osl_heisenbridge('heisenbridge')).to notify('osl_synapse[chat.example.org]').to(:create)
      end

      it do
        expect(chef_run.osl_heisenbridge('heisenbridge')).to notify('osl_synapse[chat.example.org]').to(:restart)
      end

      it do
        is_expected.to create_osl_hookshot('hookshot').with(
          host_domain: 'chat.example.org',
          config: {
            'generic' => {
              'enabled' => true,
              'urlPrefix' => 'http://chat.example.org/webhook',
              'userIdPrefix' => 'example-hook_',
            },
          },
          tag: 'latest',
          key_github: nil
        )
      end

      it do
        expect(chef_run.osl_hookshot('hookshot')).to \
          notify('osl_dockercompose[synapse_service_chat_example_org]').to(:rebuild)
      end

      it do
        expect(chef_run.osl_hookshot('hookshot')).to \
          notify('osl_dockercompose[synapse_service_chat_example_org]').to(:restart)
      end

      it do
        expect(chef_run.osl_hookshot('hookshot')).to notify('osl_synapse[chat.example.org]').to(:create)
      end

      it do
        expect(chef_run.osl_hookshot('hookshot')).to notify('osl_synapse[chat.example.org]').to(:restart)
      end

      it do
        is_expected.to create_osl_matrix_irc('matrix-appservice-irc').with(
          host_domain: 'chat.example.org',
          config: {
            'ircService' => {
              'servers' => {
                'ircd' => {},
              },
            },
          },
          tag: 'latest',
          users_regex: '@as-irc_.*'
        )
      end

      it do
        expect(chef_run.osl_matrix_irc('matrix-appservice-irc')).to \
          notify('osl_dockercompose[synapse_service_chat_example_org]').to(:rebuild)
      end

      it do
        expect(chef_run.osl_matrix_irc('matrix-appservice-irc')).to \
          notify('osl_dockercompose[synapse_service_chat_example_org]').to(:restart)
      end

      it do
        expect(chef_run.osl_matrix_irc('matrix-appservice-irc')).to notify('osl_synapse[chat.example.org]').to(:create)
      end

      it do
        expect(chef_run.osl_matrix_irc('matrix-appservice-irc')).to notify('osl_synapse[chat.example.org]').to(:restart)
      end

      it do
        is_expected.to create_osl_matrix_user('mjolnir').with(
          password: 'mjolnir',
          admin: true,
          domain: 'chat.example.org',
          homeserver_url: 'http://localhost:8008'
        )
      end

      it { is_expected.to token_osl_matrix_user 'mjolnir' }

      it do
        is_expected.to create_osl_matrix_channel('mjolnir').with(
          display_name: 'mjolnir',
          domain: 'chat.example.org',
          homeserver_url: 'http://localhost:8008'
        )
      end

      it do
        is_expected.to create_osl_mjolnir('mjolnir').with(
          host_domain: 'chat.example.org',
          config: {},
          tag: 'latest'
        )
      end

      it do
        expect(chef_run.osl_mjolnir('mjolnir')).to \
          notify('osl_dockercompose[synapse_service_chat_example_org]').to(:rebuild)
      end

      it do
        expect(chef_run.osl_mjolnir('mjolnir')).to \
          notify('osl_dockercompose[synapse_service_chat_example_org]').to(:restart)
      end

      it do
        expect(chef_run.osl_mjolnir('mjolnir')).to notify('osl_synapse[chat.example.org]').to(:create)
      end

      it do
        expect(chef_run.osl_mjolnir('mjolnir')).to notify('osl_synapse[chat.example.org]').to(:restart)
      end

      it { is_expected.to create_directory '/opt/synapse-chat.example.org/bin' }

      it do
        is_expected.to create_template('/opt/synapse-chat.example.org/bin/docker_compose').with(
          source: 'docker_compose.erb',
          cookbook: 'osl-matrix',
          mode: '0755',
          variables: {
            directory: '/opt/synapse-chat.example.org/compose',
            project: 'synapse_service_chat_example_org',
            config_files: %w(
              docker-hookshot.yaml
              docker-heisenbridge.yaml
              docker-matrix-appservice-irc.yaml
              docker-mjolnir.yaml
            ),
          }
        )
      end
    end
  end
end
