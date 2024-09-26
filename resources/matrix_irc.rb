# osl_matrix_irc
#
# Matrix-Appservice-IRC is an IRC bouncer developed by Matrix.

resource_name :osl_matrix_irc
provides :osl_matrix_irc
unified_mode true

default_action :create

property :container_name, String, name_property: true
property :config, Hash, default: {}
property :port, Integer, default: 8090
property :host_domain, String, required: true
property :host_name, String, default: lazy { "synapse-#{host_domain}" }
property :host_path, String, default: lazy { "/opt/#{host_name}" }
property :key_appservice, String, default: lazy { osl_matrix_genkey(host_name + container_name) }
property :key_homeserver, String, default: lazy { osl_matrix_genkey(container_name + host_name) }
property :tag, String, default: 'latest'
property :sensitive, [true, false], default: true
property :users_regex, String, default: '@as-irc_.*'

action :create do
  # Pull down the latest version
  docker_image 'matrixdotorg/matrix-appservice-irc' do
    tag new_resource.tag
  end

  # Generate the app service file
  osl_synapse_appservice(
    'matrix-appservice-irc',
    "http://#{new_resource.container_name}:#{new_resource.port}",
    new_resource.key_appservice,
    new_resource.key_homeserver,
    'appservice-irc',
    {
      'users' => [
        {
          'exclusive' => true,
          'regex' => new_resource.users_regex,
        },
      ],
      'rate_limited' => false,
      'protocols' => [
        'irc',
      ],
    }
  )

  # Generate the config file
  file "#{new_resource.host_path}/#{new_resource.container_name}-config.yaml" do
    content osl_matrix_irc_defaults(new_resource.config)
    owner 'synapse'
    group 'synapse'
    mode '400'
    sensitive true
  end

  # Generate the passkey, one time
  execute 'Generating Matrix-Appservice-IRC Passkey' do
    command "openssl genpkey -out \"#{new_resource.host_path}/keys/irc-passkey.pem\" -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:2048; chmod 400 '#{new_resource.host_path}/keys/irc-passkey.pem'"
    user 'synapse'
    group 'synapse'
    creates "#{new_resource.host_path}/keys/irc-passkey.pem"
  end

  # Generate the signingkey, one time
  # While we will NOT be using the media proxy, the bridge still requires this file.
  # Using docker_container always throws a 400 HTTP error, executing docker works fine. Review requested.
  # ---
  #  docker_container 'Generate signingkey' do
  #    repo 'matrixdotorg/matrix-appservice-irc'
  #    autoremove true
  #    volume "#{new_resource.host_path}/keys:/data"
  #    entrypoint 'sh'
  #    command ['-c', 'node lib/generate-signing-key.js > /data/signingkey.jwk && chmod 400 /data/signingkey.jwk']
  #    user osl_synapse_user
  #    not_if { ::File.exist?("#{new_resource.host_path}/keys/irc-signingkey.jwk") }
  #  end
  execute 'Generate signingkey' do
    command "docker run --rm --entrypoint \"sh\" --volume #{new_resource.host_path}/keys:/data --user #{osl_synapse_user} matrixdotorg/matrix-appservice-irc \"-c\" \"node lib/generate-signing-key.js > /data/signingkey.jwk && chmod 400 /data/signingkey.jwk\""
    creates "#{new_resource.host_path}/keys/signingkey.jwk"
  end

  # Generate the compose config
  # Adding the PostgreSQL database as a container, instead of using an outside source, due to how little the DB needs to manage.
  config_compose = {
    'services' => {
      "#{new_resource.container_name}-postgres" => {
        'image' => 'postgres:16',
        'volumes' => [
          "#{new_resource.host_path}/appservice-data/#{new_resource.container_name}-postgres/:/var/lib/postgresql/data",
        ],
        'environment' => {
          'POSTGRES_PASSWORD' => osl_matrix_genkey(new_resource.container_name),
        },
        'restart' => 'always',
      },
      new_resource.container_name => {
        'image' => "matrixdotorg/matrix-appservice-irc:#{new_resource.tag}",
        'volumes' => [
          "#{new_resource.host_path}/appservice/#{new_resource.container_name}.yaml:/data/appservice-registration-irc.yaml",
          "#{new_resource.host_path}/#{new_resource.container_name}-config.yaml:/data/config.yaml",
          "#{new_resource.host_path}/keys/irc-passkey.pem:/data/passkey.pem",
          "#{new_resource.host_path}/keys/signingkey.jwk:/data/signingkey.jwk",
        ],
        'user' => osl_synapse_user,
        'restart' => 'always',
        'depends_on' => ["#{new_resource.container_name}-postgres"],
      },
    },
  }

  # Generate compose file
  file "#{new_resource.host_path}/compose/docker-#{new_resource.container_name}.yaml" do
    content osl_yaml_dump(config_compose)
    owner 'synapse'
    group 'synapse'
    mode '400'
    sensitive true
  end
end
