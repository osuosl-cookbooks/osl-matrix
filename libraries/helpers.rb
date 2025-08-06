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

      # Generate the default configuraiton for Mjonir
      def osl_mjolnir_defaults(custom_config, access_token)
        {
          'homeserverUrl' => 'http://synapse:8008',
          'rawHomeserverUrl' => 'http://synapse:8008',
          'accessToken' => access_token,
          'dataPath' => '/data/storage',
          'autojoinOnlyIfManager' => true,
          'managementRoom' => new_resource.default_channel,
          'synOnStartup' => true,
          'verifyPermissionOnStartup' => true,
          'displayReports' => true,
          'nsfwSensitivity' => new_resource.nsfw_sensitivity,
          'web' => {
            'enabled' => true,
            'port' => new_resource.port_api,
            'address' => '0.0.0.0',
            'abuseReporting' => {
              'enabled' => true,
            },
          },
        }.deep_merge(custom_config)
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
          'rate_limited' => false,
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

      # Checks if the Synapse server is responsive ONCE.
      # The Chef resource's own retry mechanism will handle looping.
      def check_server_readiness(url)
        check_uri = URI("#{url}/_matrix/client/versions")
        Chef::Log.info("Checking if Synapse server is available at #{check_uri}...")
        begin
          response = Net::HTTP.get_response(check_uri)
          unless response.is_a?(Net::HTTPSuccess)
            raise "Synapse server is running but returned an error: #{response.code} #{response.message}"
          end
          Chef::Log.info('Synapse server is online.')
          true
        rescue Errno::ECONNREFUSED, Net::ReadTimeout, Net::OpenTimeout => e
          # Re-raise with a more user-friendly message for Chef logs
          raise "Could not connect to Synapse server at #{url}. Error: #{e.message}"
        end
      end

      # Fetches details for a specific user from the Synapse Admin API.
      #
      # @param user_api_url [String] The full API URL for the user.
      # @param auth_header [String] The 'Authorization: Bearer ...' token.
      # @return [Hash, nil] A hash of user data if the user exists, or nil if they do not.
      # @raise [RuntimeError] on unexpected API errors.
      def get_user_details(user_api_url, auth_header)
        uri = URI(user_api_url)
        response = perform_request(uri, method: :get, headers: { 'Authorization' => auth_header })

        case response
        when Net::HTTPSuccess
          JSON.parse(response.body)
        when Net::HTTPNotFound
          nil # User does not exist
        else
          raise "Error checking user #{user_api_url}. Response: #{response.code} #{response.message} - #{response.body}"
        end
      end

      # Creates or updates a user via the Synapse Admin API.
      #
      # @param user_api_url [String] The full API URL for the user.
      # @param auth_header [String] The 'Authorization: Bearer ...' token.
      # @param payload [Hash] The data to send in the PUT request body.
      # @return [true] on success.
      # @raise [RuntimeError] on failure.
      def create_or_update_user(user_api_url, auth_header, payload)
        uri = URI(user_api_url)
        response = perform_request(uri, method: :put, headers: { 'Authorization' => auth_header }, body: payload)

        unless response.is_a?(Net::HTTPSuccess) || response.is_a?(Net::HTTPCreated)
          raise "Failed to create/update user #{user_api_url}: #{response.code} - #{response.body}"
        end
        true
      end

      # Registers the initial admin user using the HMAC-authenticated Admin API.
      # This version correctly implements the two-step GET/POST flow as per the
      # official Synapse documentation.
      #
      # @param server_url [String] The base URL of the Synapse homeserver.
      # @param username [String] The localpart of the user ID for the new admin.
      # @param password [String] The password for the new admin.
      # @param shared_secret [String] The registration_shared_secret from homeserver.yaml.
      # @return [String] The access token for the newly created admin user.
      # @raise [RuntimeError] on any failure.
      def register_initial_admin(server_url, username, password, shared_secret)
        register_uri = URI("#{server_url}/_synapse/admin/v1/register")

        # Make a GET request to fetch a nonce from the server.
        Chef::Log.info("Requesting registration nonce from #{register_uri}...")
        nonce_response = perform_request(register_uri, method: :get)
        unless nonce_response.is_a?(Net::HTTPSuccess)
          raise "Failed to get registration nonce from Synapse. Response: #{nonce_response.code} #{nonce_response.body}"
        end

        nonce_data = JSON.parse(nonce_response.body)
        nonce = nonce_data['nonce']
        raise 'Could not find a valid nonce in the server response.' if nonce.nil?
        Chef::Log.info("Successfully received registration nonce: #{nonce}")

        # Calculate the HMAC-SHA1 signature using the server-provided nonce.
        message = [nonce, username, password, 'admin'].join("\x00")

        hmac = OpenSSL::HMAC.hexdigest('sha1', shared_secret.strip, message)
        Chef::Log.info("Calculated HMAC for new admin user @#{username}")

        # Construct the payload for the POST request, including the nonce we received.
        payload = {
          nonce: nonce,
          username: username,
          displayname: "#{username} (Admin)",
          password: password,
          admin: true,
          mac: hmac,
        }

        # Perform the POST request to complete the registration.
        reg_response = perform_request(register_uri, method: :post, body: payload)

        # Process the response.
        unless reg_response.is_a?(Net::HTTPSuccess) || reg_response.is_a?(Net::HTTPCreated)
          error_body = reg_response.body
          if error_body.include?('M_USER_IN_USE')
            raise "Failed to register admin user: The user ID '#{username}' is already taken. " \
                  'If the user exists but the token file was lost, you must manually delete the user.'
          elsif error_body.include?('M_INVALID_MAC')
            raise 'Failed to register admin user: Invalid MAC. This almost always means the ' \
                  "'shared_secret' provided does not match the one in homeserver.yaml."
          else
            raise "Failed to register initial admin user. Response: #{reg_response.code} #{error_body}"
          end
        end

        # Extract and return the access token.
        reg_data = JSON.parse(reg_response.body)
        access_token = reg_data['access_token']
        raise 'Registration succeeded but no access_token was returned.' if access_token.nil?

        Chef::Log.info('Successfully registered admin user and received access token.')
        access_token
      end

      # Logs in as a specific user to retrieve a valid access token for them.
      # This requires a valid admin access token for authentication.
      #
      # @param server_url [String] The base URL of the Synapse homeserver.
      # @param admin_token [String] The access token of a server admin.
      # @param user_id [String] The full Matrix ID of the user to log in as (e.g., '@alice:your.server').
      # @param device_id [String] An optional device ID to associate with the new token.
      # @return [String] A new access token for the specified user.
      # @raise [RuntimeError] on any failure.
      def login_as_user(server_url, admin_token, user_id, device_id: 'Chef-Login')
        # Define the correct API endpoint, ensuring the user_id is URL-encoded.
        login_uri = URI("#{server_url}/_synapse/admin/v1/users/#{URI.encode_www_form_component(user_id)}/login")

        #  Prepare the authentication header using the admin's token.
        headers = { 'Authorization' => "Bearer #{admin_token.strip}" }

        # Prepare the request payload.
        payload = { device_id: device_id }

        Chef::Log.info("Requesting new access token for user #{user_id}...")

        # Perform the POST request.
        response = perform_request(login_uri, method: :post, headers: headers, body: payload)

        # Process the response with specific error handling.
        case response
        when Net::HTTPSuccess
          login_data = JSON.parse(response.body)
          access_token = login_data['access_token']

          # Defensive check in case the API changes
          raise 'Login succeeded but no access_token was returned.' if access_token.nil?

          Chef::Log.info("Successfully retrieved new access token for #{user_id}.")
          access_token
        when Net::HTTPUnauthorized
          raise 'Authentication failed when trying to get a user token. Is the admin_token valid?'
        when Net::HTTPForbidden
          raise 'Authorization failed. The user associated with the admin_token is not a server administrator.'
        when Net::HTTPNotFound
          raise "Cannot get token. The user #{user_id} was not found."
        else
          raise "Failed to log in as user #{user_id}. Response: #{response.code} #{response.body}"
        end
      end

      # Checks if a room alias (e.g., #channel:your.server) already exists.
      #
      # @param server_url [String] The base URL of the Synapse homeserver.
      # @param full_alias [String] The full room alias to check.
      # @return [Boolean] True if the alias exists, false if not.
      # @raise [RuntimeError] on unexpected errors.
      def channel_alias_exists?(server_url, full_alias)
        # The alias must be URL-encoded for the API path.
        encoded_alias = URI.encode_www_form_component(full_alias)
        alias_uri = URI("#{server_url}/_matrix/client/v3/directory/room/#{encoded_alias}")

        Chef::Log.info("Checking for existence of room alias #{full_alias}...")

        response = perform_request(alias_uri, method: :get)

        case response
        when Net::HTTPSuccess
          Chef::Log.info("Room alias #{full_alias} already exists.")
          true
        when Net::HTTPNotFound
          Chef::Log.info("Room alias #{full_alias} does not exist.")
          false
        else
          raise "Error checking room alias #{full_alias}. Response: #{response.code} #{response.body}"
        end
      end

      # Creates a new room (channel) as a specific user.
      #
      # @param server_url [String] The base URL of the Synapse homeserver.
      # @param access_token [String] The access token of the user creating the room.
      # @param display_name [String] The public name of the room.
      # @param channel_alias [String] The localpart of the alias (e.g., 'my-channel').
      # @param topic [String] The room's topic.
      # @param public [Boolean] Whether the room should be public or private.
      # @return [true] on success.
      # @raise [RuntimeError] on failure.
      def create_channel(server_url, access_token, display_name, channel_alias, topic, public)
        create_uri = URI("#{server_url}/_matrix/client/v3/createRoom")
        headers = { 'Authorization' => "Bearer #{access_token.strip}" }

        # The 'preset' simplifies setting multiple room properties at once.
        preset = public ? 'public_chat' : 'private_chat'
        visibility = public ? 'public' : 'private'

        payload = {
          preset: preset,
          visibility: visibility,
          name: display_name,
          topic: topic,
          room_alias_name: channel_alias, # API uses the localpart of the alias here
        }

        Chef::Log.info("Attempting to create channel ##{channel_alias}...")
        response = perform_request(create_uri, method: :post, headers: headers, body: payload)

        unless response.is_a?(Net::HTTPSuccess)
          raise "Failed to create channel. Response: #{response.code} #{response.body}"
        end

        Chef::Log.info("Successfully created channel with alias ##{channel_alias}.")
        true
      end

      private

      # Generic helper to perform an HTTP request.
      def perform_request(uri, method: :get, headers: {}, body: nil)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = (uri.scheme == 'https')

        request_class = Net::HTTP.const_get(method.to_s.capitalize)
        request = request_class.new(uri.request_uri)
        request.body = body.to_json if body

        headers.each { |k, v| request[k] = v }
        request['Content-Type'] = 'application/json'

        http.request(request)
      end

      def appservices
        return [] unless Dir.exist?("#{new_resource.path}/appservice")

        ::Dir.entries("#{new_resource.path}/appservice")
             .select { |f| f.end_with?('.yaml') }
             .map { |f| File.basename(f, '.yaml') }
      end
    end
  end
end
Chef::DSL::Recipe.include ::OSLMatrix::Cookbook::Helpers
Chef::Resource.include ::OSLMatrix::Cookbook::Helpers
