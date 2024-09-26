module OSLMatrix
  module Cookbook
    module Helpers
      # Class function override for Hashes.
      # Traditional merge does not merge any child Hashes.
      # deep_merge allows for recursively merging child Hashes.
      # Code taken from: https://stackoverflow.com/a/9381776
      class ::Hash
        def deep_merge(second)
          merger = proc { |_key, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : v2 }
          merge(second, &merger)
        end
      end

      # Generate a secret key through hashing a string. Mainly used when wanting a registration key
      # WARNING: Not recommended for an actual deployment, only done when no secret is given.
      def osl_matrix_genkey(plain_text)
        require 'digest'
        Digest::MD5.hexdigest(plain_text)
      end

      # Get the default values for a synapse homeserver config.
      def osl_homeserver_defaults(domain, pg_info, appservices)
        {
          'server_name' => domain,
          'pid_file' => '/data/homeserver.pid',
          'media_store_path' => '/data/media_store',
          'report_stats' => false,
          'listeners' => [
            {
              'port' => 8008,
              'tls' => false,
              'type' => 'http',
              'x_forwarded' => true,
              'resources' => [
                {
                  'names' => %w(client federation),
                  'compress' => false,
                },
              ],
            },
          ],
          'database' => osl_homeserver_db_defaults(pg_info),
          'app_service_config_files' => appservices.map { |app| "/data/appservice/#{app}.yaml" },
          'registration_shared_secret_path' => '/data/keys/registration.key',
          'signing_key_path' => '/data/keys/signing.key',
          'url_preview_enabled' => true,
          'url_preview_ip_range_blacklist' => [
            '127.0.0.0/8',
            '10.0.0.0/8',
            '172.16.0.0/12',
            '192.168.0.0/16',
            '100.64.0.0/10',
            '192.0.0.0/24',
            '169.254.0.0/16',
            '192.88.99.0/24',
            '198.18.0.0/15',
            '192.0.2.0/24',
            '198.51.100.0/24',
            '203.0.113.0/24',
            '224.0.0.0/4',
            '::1/128',
            'fe80::/10',
            'fc00::/7',
            '2001:db8::/32',
            'ff00::/8',
            'fec0::/10',
          ],
        }
      end

      # Generate the default configuration for a homeserver's database settings
      def osl_homeserver_db_defaults(pg_info)
        if pg_info[:username] && pg_info[:password] && pg_info[:database] && pg_info[:host]
          # Connect to PosgreSQL server
          {
            'name' => 'psycopg2',
            'args' => {
              'user' => pg_info[:username],
              'password' => pg_info[:password],
              'database' => pg_info[:database],
              'host' => pg_info[:host],
              'cp_min' => 5,
              'cp_max' => 10,
            },
          }
        else
          # Use SQLite
          {
            'name' => 'sqlite3',
            'args' => {
              'database' => '/data/homeserver-sqlite.db',
            },
          }
        end
      end

      # Generate the default configuration for matrix-appservice-irc
      def osl_matrix_irc_defaults(custom_config)
        default_config = {
          'homeserver' => {
            'url' => 'http://synapse:8008',
            'domain' => new_resource.host_domain,
          },
          'ircService' => {
            'passwordEncryptionKeyPath' => '/data/passkey.pem',
            'mediaProxy' => {
              'signingKeyPath' => '/data/signingkey.jwk',
              'ttlSeconds' => 3600,
              'bindPort' => 11111,
              'publicUrl' => 'http://irc-media-proxy-not-implemented.localhost',
            },
            'permissions' => {
              new_resource.host_domain => 'admin',
            },
          },
          'database' => {
            'engine' => 'postgres',
            'connectionString' => "postgres://postgres:#{osl_matrix_genkey(new_resource.container_name)}@#{new_resource.container_name}-postgres:5432/postgres",
          },
        }.deep_merge(custom_config)

        # Loop over all IRC servers, adding their defaults.
        begin
          custom_config['ircService']['servers'].each do |server, server_config|
            default_config['ircService']['servers'][server] = osl_matrix_irc_server_defaults(server_config)
          end
        rescue
          # No servers given
        end

        # Do a final merge
        osl_yaml_dump(default_config)
      end

      # Generate the default configuration for every IRC server
      def osl_matrix_irc_server_defaults(custom_config)
        {
          'name' => 'Untitled IRC Server',
          'botConfig' => {
            'enabled' => true,
            'username' => 'oslmatrixbot',
          },
          'dynamicChannels' => {
            'enabled' => true,
            'published' => false,
            'aliasTemplate' => '#irc_$SERVER_$CHANNEL',
          },
          'matrixClients' => {
            'userTemplate' => '@$SERVER_$NICK',
          },
          'ircClients' => {
            'nickTemplate' => '$DISPLAY[m]',
            'kickOn' => {
              'channelJoinFailure' => true,
              'ircConnectionFailure' => true,
              'userQuit' => true,
            },
          },
        }.deep_merge(custom_config)
      end

      # Get the name of the synapse docker container name, given the name of the synapse resource which creates it
      def osl_synapse_docker_name(synapse_resource)
        # Get the resource, and return the name
        find_resource(:osl_synapse, synapse_resource).name
      end

      # Create an app service file for Matrix Synapse
      def osl_synapse_appservice(id, url, appservicekey, homeserverkey, service, namespace)
        appservice_data = {
          'id' => id,
          'url' => url,
          'as_token' => appservicekey,
          'hs_token' => homeserverkey,
          'rate_limited' => 'false',
          'sender_localpart' => service,
        }

        appservice_data['namespaces'] = namespace if namespace

        file "#{new_resource.host_path}/appservice/#{new_resource.container_name}.yaml" do
          content osl_yaml_dump(appservice_data)
          owner 'synapse'
          group 'synapse'
          mode '400'
          sensitive true
        end
      end

      # Convert Hash to YAML string, without file header
      def osl_yaml_dump(hash_map)
        YAML.dump(hash_map).lines[1..-1].join
      end

      # Get the UID and GID of the synapse user
      def osl_synapse_user
        "#{Etc.getpwnam('synapse').uid.to_s}:#{Etc.getpwnam('synapse').gid.to_s}"
      end
    end
  end
end
Chef::DSL::Recipe.include ::OSLMatrix::Cookbook::Helpers
Chef::Resource.include ::OSLMatrix::Cookbook::Helpers
