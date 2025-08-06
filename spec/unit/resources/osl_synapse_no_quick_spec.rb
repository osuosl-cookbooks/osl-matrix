#
# Cookbook:: osl-matrix
# Spec:: osl_synapse, osl_heisenbridge, osl_hookshot
#
# Copyright:: 2023-2025, Oregon State University
#

require_relative '../../spec_helper'

describe 'osl-matrix-test::synapse-no-quick' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge({
          step_into: %w(
            osl_heisenbridge
            osl_hookshot
            osl_matrix_admin_user
            osl_matrix_channel
            osl_matrix_irc
            osl_matrix_user
            osl_mjolnir
            osl_synapse
          ),
        })).converge(described_recipe)
      end

      include_context 'pwnam'
      include_context 'common'

      # osl_synapse
      it { is_expected.to pull_docker_image('matrixdotorg/synapse').with(tag: 'latest') }

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
          sensitive: true,
          content: <<~EOF
            modules:
            - module: ldap_auth_provider.LdapAuthProviderModule
              config:
                enabled: true
                uri: ldap://ldap.osuosl.org:389
                start_tls: true
                base: ou=People,dc=osuosl,dc=org
                attributes:
                  uid: uid
                  mail: mail
                  name: givenName
            server_name: chat.example.org
            pid_file: "/data/homeserver.pid"
            media_store_path: "/data/media_store"
            report_stats: false
            listeners:
            - port: 8008
              tls: false
              type: http
              x_forwarded: true
              resources:
              - names:
                - client
                - federation
                compress: false
            database:
              name: psycopg2
              args:
                user: synapse
                password: password
                database: synapse
                host: 10.0.0.2
                cp_min: 5
                cp_max: 10
            app_service_config_files: []
            registration_shared_secret_path: "/data/keys/registration.key"
            signing_key_path: "/data/keys/signing.key"
            url_preview_enabled: true
            url_preview_ip_range_blacklist:
            - 127.0.0.0/8
            - 10.0.0.0/8
            - 172.16.0.0/12
            - 192.168.0.0/16
            - 100.64.0.0/10
            - 192.0.0.0/24
            - 169.254.0.0/16
            - 192.88.99.0/24
            - 198.18.0.0/15
            - 192.0.2.0/24
            - 198.51.100.0/24
            - 203.0.113.0/24
            - 224.0.0.0/4
            - "::1/128"
            - fe80::/10
            - fc00::/7
            - 2001:db8::/32
            - ff00::/8
            - fec0::/10
          EOF
        )
      end

      it do
        expect(chef_run.file('/opt/synapse-chat.example.org/homeserver.yaml')).to \
            notify('osl_dockercompose[chat_example_org]').to(:rebuild)
      end

      # Create the Synapse compose file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-synapse.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true,
          content: <<~EOF
            services:
              synapse:
                image: matrixdotorg/synapse:latest
                ports:
                - 8008:8008
                - 8448:8448
                volumes:
                - "/opt/synapse-chat.example.org:/data"
                user: '1001:'
                restart: always
                networks:
                - chat_example_org
            networks:
              chat_example_org:
                external: true
          EOF
        )
      end

      it do
        is_expected.to up_osl_dockercompose('chat_example_org').with(
          directory: '/opt/synapse-chat.example.org/compose',
          config_files: %w(docker-synapse.yaml)
        )
      end

      # osl_matrix_admin_user
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/keys/admin-access_token.key').with(
          content: 'admin_access_token',
          mode: '0600',
          sensitive: true
        )
      end

      # osl_matrix_user
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/keys/mjolnir-access_token.key').with(
          content: 'login_as_user_access_token',
          mode: '0600',
          sensitive: true
        )
      end

      # osl_heisenbridge
      it { is_expected.to pull_docker_image('hif1/heisenbridge').with(tag: 'latest') }

      # Appservice file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/appservice/osl-irc-bridge.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true,
          content: <<~EOF
            id: heisenbridge
            url: http://osl-irc-bridge:9898
            as_token: f2fcc18e3e4468fde3f0c956754b69f2
            hs_token: a356e2ef9ff56417e4943f7a8eae9455
            rate_limited: false
            sender_localpart: heisenbridge
            namespaces:
              users:
              - exclusive: true
                regex: "@irc_.*"
          EOF
        )
      end

      # Create the Heisenbridge compose file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-osl-irc-bridge.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true,
          content: <<~EOF
            services:
              osl-irc-bridge:
                entrypoint: python -m heisenbridge -c /data/osl-irc-bridge.yaml http://synapse:8008
                image: hif1/heisenbridge:latest
                volumes:
                - "/opt/synapse-chat.example.org/appservice/osl-irc-bridge.yaml:/data/osl-irc-bridge.yaml"
                user: '1001:'
                restart: always
                networks:
                - chat_example_org
            networks:
              chat_example_org:
                external: true
          EOF
        )
      end

      # osl_hookshot
      it { is_expected.to pull_docker_image('halfshot/matrix-hookshot').with(tag: 'latest') }

      # Appservice file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/appservice/osl-hookshot-webhook.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true,
          content: <<~EOF
            id: hookshot
            url: http://osl-hookshot-webhook:9993
            as_token: 7bac9cad4f2155c0049ffcdd2b4fea9d
            hs_token: 0e2b3bf52c4a5a1d6cc559fa7052d227
            rate_limited: false
            sender_localpart: hookshot
            namespaces:
              users:
              - exclusive: true
                regex: "@my-amazing-hook_.*"
          EOF
        )
      end

      # Generate passkey file
      it do
        is_expected.to run_execute('Generating Hookshot Passkey').with(
          command: "openssl genpkey -out \"/opt/synapse-chat.example.org/keys/hookshot.pem\" -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096; chmod 400 '/opt/synapse-chat.example.org/keys/hookshot.pem'",
          user: 'synapse',
          group: 'synapse',
          sensitive: true,
          creates: '/opt/synapse-chat.example.org/keys/hookshot.pem'
        )
      end

      # Generate config file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/osl-hookshot-webhook-config.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true,
          content: <<~EOF
            permissions:
            - actor: chat.example.org
              services:
              - service: "*"
                level: admin
            generic:
              enabled: true
              urlPrefix: http://chat.example.org/webhook
              userIdPrefix: my-amazing-hook_
            passFile: "/data/keys/hookshot.pem"
            bridge:
              domain: chat.example.org
              url: http://synapse:8008
              port: 9993
              bindAddress: 0.0.0.0
            listeners:
            - port: 9000
              bindAddress: 0.0.0.0
              resources:
              - webhooks
            - port: 9001
              bindAddress: 0.0.0.0
              resources:
              - metrics
              - provisioning
            - port: 9002
              bindAddress: 0.0.0.0
              resources:
              - widgets
          EOF
        )
      end

      # Create Hookshot compose file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-osl-hookshot-webhook.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true,
          content: <<~EOF
            services:
              osl-hookshot-webhook:
                image: halfshot/matrix-hookshot:latest
                ports:
                - 9000:9000
                - 9001:9001
                - 9002:9002
                volumes:
                - "/opt/synapse-chat.example.org/appservice/osl-hookshot-webhook.yaml:/data/registration.yml"
                - "/opt/synapse-chat.example.org/osl-hookshot-webhook-config.yaml:/data/config.yml"
                - "/opt/synapse-chat.example.org/keys/hookshot.pem:/data/keys/hookshot.pem"
                - "/opt/synapse-chat.example.org/keys/github-key.pem:/data/keys/github-key.pem"
                user: '1001:'
                restart: always
                networks:
                - chat_example_org
            networks:
              chat_example_org:
                external: true
          EOF
        )
      end

      # osl_matrix_irc
      it { is_expected.to pull_docker_image('matrixdotorg/matrix-appservice-irc').with(tag: 'latest') }

      # Appservice file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/appservice/osl-matrix-irc.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true,
          content: <<~EOF
            id: matrix-appservice-irc
            url: http://osl-matrix-irc:8090
            as_token: 9d2fe4417b7f68ed878797a8f547f0c6
            hs_token: 9568b486ab0c81aec3da41b89209021e
            rate_limited: false
            sender_localpart: appservice-irc
            namespaces:
              users:
              - exclusive: true
                regex: "@as-irc_.*"
              rate_limited: false
              protocols:
              - irc
          EOF
        )
      end

      # Generate passkey file
      it do
        is_expected.to run_execute('Generating Matrix-Appservice-IRC Passkey').with(
          command: "openssl genpkey -out \"/opt/synapse-chat.example.org/keys/irc-passkey.pem\" -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:2048; chmod 400 '/opt/synapse-chat.example.org/keys/irc-passkey.pem'",
          user: 'synapse',
          group: 'synapse',
          sensitive: true,
          creates: '/opt/synapse-chat.example.org/keys/irc-passkey.pem'
        )
      end

      # Generate signing key file
      it do
        is_expected.to run_execute('Generate signingkey').with(
          command: 'docker run --rm --entrypoint "sh" --volume /opt/synapse-chat.example.org/keys:/data --user 1001: matrixdotorg/matrix-appservice-irc "-c" "node lib/generate-signing-key.js > /data/signingkey.jwk && chmod 400 /data/signingkey.jwk"',
          sensitive: true,
          creates: '/opt/synapse-chat.example.org/keys/signingkey.jwk'
        )
      end

      # Generate config file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/osl-matrix-irc-config.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true,
          content: <<~EOF
            homeserver:
              url: http://synapse:8008
              domain: chat.example.org
            ircService:
              passwordEncryptionKeyPath: "/data/passkey.pem"
              mediaProxy:
                signingKeyPath: "/data/signingkey.jwk"
                ttlSeconds: 3600
                bindPort: 11111
                publicUrl: http://irc-media-proxy-not-implemented.localhost
              permissions:
                chat.example.org: admin
              servers:
                ircd:
                  name: Untitled IRC Server
                  botConfig:
                    enabled: true
                    username: oslmatrixbot
                  dynamicChannels:
                    enabled: true
                    published: false
                    aliasTemplate: "#irc_$SERVER_$CHANNEL"
                  matrixClients:
                    userTemplate: "@$SERVER_$NICK"
                  ircClients:
                    nickTemplate: "$DISPLAY[m]"
                    kickOn:
                      channelJoinFailure: true
                      ircConnectionFailure: true
                      userQuit: true
            database:
              engine: postgres
              connectionString: postgres://postgres:498f6c83004a9c8bb719b9082880ae03@osl-matrix-irc-postgres:5432/postgres
          EOF
        )
      end

      # Create matrix-appservice-irc compose file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-osl-matrix-irc.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true,
          content: <<~EOF
            services:
              osl-matrix-irc-postgres:
                image: postgres:16
                volumes:
                - "/opt/synapse-chat.example.org/appservice-data/osl-matrix-irc-postgres/:/var/lib/postgresql/data"
                environment:
                  POSTGRES_PASSWORD: 498f6c83004a9c8bb719b9082880ae03
                restart: always
                networks:
                - chat_example_org
              osl-matrix-irc:
                image: matrixdotorg/matrix-appservice-irc:latest
                volumes:
                - "/opt/synapse-chat.example.org/appservice/osl-matrix-irc.yaml:/data/appservice-registration-irc.yaml"
                - "/opt/synapse-chat.example.org/osl-matrix-irc-config.yaml:/data/config.yaml"
                - "/opt/synapse-chat.example.org/keys/irc-passkey.pem:/data/passkey.pem"
                - "/opt/synapse-chat.example.org/keys/signingkey.jwk:/data/signingkey.jwk"
                user: '1001:'
                restart: always
                depends_on:
                - osl-matrix-irc-postgres
                networks:
                - chat_example_org
            networks:
              chat_example_org:
                external: true
          EOF
        )
      end

      # osl_mjolnir
      it { is_expected.to pull_docker_image('matrixdotorg/mjolnir').with(tag: 'latest') }

      # Appservice file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/appservice/osl-moderate.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true,
          content: <<~EOF
            id: mjolnir
            url: http://osl-moderate:9899
            as_token: e680b928a664a6340c312fc949bb8bac
            hs_token: 80bf4f410475528be444a23f4e5d5ece
            rate_limited: false
            sender_localpart: mjolnir-as
            namespaces: {}
          EOF
        )
      end

      # Generate config file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/osl-moderate-config.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true,
          content: <<~EOF
            homeserverUrl: http://synapse:8008
            rawHomeserverUrl: http://synapse:8008
            accessToken: mjolnir_access_token
            dataPath: "/data/storage"
            autojoinOnlyIfManager: true
            managementRoom: "#mjolnir:chat.example.org"
            synOnStartup: true
            verifyPermissionOnStartup: true
            displayReports: true
            nsfwSensitivity: 0.6
            web:
              enabled: true
              port: 9003
              address: 0.0.0.0
              abuseReporting:
                enabled: true
          EOF
        )
      end

      # Create Hookshot compose file
      it do
        is_expected.to create_file('/opt/synapse-chat.example.org/compose/docker-osl-moderate.yaml').with(
          owner: 'synapse',
          group: 'synapse',
          mode: '400',
          sensitive: true,
          content: <<~EOF
            services:
              osl-moderate:
                command: bot --mjolnir-config /data/config.yaml
                image: matrixdotorg/mjolnir:latest
                volumes:
                - "/opt/synapse-chat.example.org/appservice/osl-moderate.yaml:/data/appservice.yaml:ro"
                - "/opt/synapse-chat.example.org/osl-moderate-config.yaml:/data/config.yaml:ro"
                - "/opt/synapse-chat.example.org/appservice-data/osl-moderate:/data"
                ports:
                - 9003:9003
                restart: always
                networks:
                - chat_example_org
            networks:
              chat_example_org:
                external: true
          EOF
        )
      end
    end
  end
end
