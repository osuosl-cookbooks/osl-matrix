module OSLMatrix
  module Cookbook
    module Helpers
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
