# osl_hookshot
#
# Hookshot is a webhook bot for a Matrix server.
# Designed to only connect to a Synapse instance

resource_name :osl_hookshot
provides :osl_hookshot
unified_mode true

default_action :create

property :config, Hash, required: true
property :container_name, String, name_property: true
property :port, Integer, default: 9993
property :port_webhook, Integer, default: 9000
property :port_metric, Integer, default: 9001
property :port_widget, Integer, default: 9002
property :host_domain, String, required: true
property :host_name, String, default: lazy { "synapse-#{host_domain}" }
property :host_path, String, default: lazy { "/opt/#{host_name}" }
property :key_appservice, String, default: lazy { osl_matrix_genkey(host_name + container_name) }
property :key_homeserver, String, default: lazy { osl_matrix_genkey(container_name + host_name) }
property :key_github, String
property :tag, String, default: 'latest'
property :sensitive, [true, false], default: true

action :create do
  compose_name = new_resource.host_domain.gsub('.', '_')

  # Pull down the latest version
  docker_image 'halfshot/matrix-hookshot' do
    tag new_resource.tag
  end

  # Parse out all of the instance of userIdPrefix in order to modify the appservice registration
  arrAppServiceUsers = []
  # Get the config from the new resource, and put into a mutable variable
  config = new_resource.config
  # Loop over the root hash
  config.each_value do |val|
    # Check to see if the sub-hash has a key called userIDPrefix
    unless val.is_a?(Hash) && val.key?('userIdPrefix')
      next
    end
    # Add the userIDPrefix
    arrAppServiceUsers.push({
      'exclusive' => true,
      'regex' => "@#{val['userIdPrefix']}.*",
    })
  end

  # Add in something if there was nothing given
  unless arrAppServiceUsers
    arrAppServiceUsers.push({
      'exclusive' => true,
      'regex' => '\'@webhook_.*\'',
    })
  end

  # Generate the app service file
  osl_synapse_appservice(
    'hookshot',
    "http://#{new_resource.container_name}:#{new_resource.port}",
    new_resource.key_appservice,
    new_resource.key_homeserver,
    'hookshot',
    {
      'users' => arrAppServiceUsers,
    }
  )

  # Auto configuration for the homeserver, ignore if already set
  # Passkey settings
  # Not usually needed to be modified by user, as we generate our own, but just in case.
  config.merge!({
    'passFile' => '/data/keys/hookshot.pem',
  }) { |_key, old_value, new_value| old_value || new_value }

  # Bridge settings
  # Ensure the bridge key hash exists
  config['bridge'] = {} unless config['bridge']
  config['bridge'].merge!({
    'domain' => new_resource.host_domain,
    'url' => "http://synapse:#{find_resource(:osl_synapse, new_resource.host_domain).port}", # Find the synapse resource, and get the port
    'port' => new_resource.port,
    'bindAddress' => '0.0.0.0',
  }) { |_key, old_value, new_value| old_value || new_value }

  # Listeners settings
  # Force the automatically generated configuration, custom config goes against the spirit of some properties.
  if config['listeners']
    # Get the information about where the resource is declared, and tell the developer that there will be changes to the defined key.
    pResource = find_resource(:osl_hookshot, new_resource.container_name)
    log 'Checking for overwriting custom configuration' do
      message "#{pResource.source_line}: Any definitions within the listeners key will be overwritten by the resource. Please read documentation for more information."
      level :warn
    end
  end

  config['listeners'] = [
    {
      'port' => new_resource.port_webhook,
      'bindAddress' => '0.0.0.0',
      'resources' => [
        'webhooks',
      ],
    },
    {
      'port' => new_resource.port_metric,
      'bindAddress' => '0.0.0.0',
      'resources' => %w(
        metrics
        provisioning
      ),
    },
    {
      'port' => new_resource.port_widget,
      'bindAddress' => '0.0.0.0',
      'resources' => [
        'widgets',
      ],
    },
  ]

  # Check to see if we should add a github key
  if new_resource.key_github
    # We have a github key, add the file, and append the key to the config
    file "#{new_resource.host_path}/keys/github-key.pem" do
      content new_resource.key_github
      owner 'synapse'
      group 'synapse'
      mode '400'
      sensitive true
    end

    config['github']['auth']['privateKeyFile'] = '/data/keys/github-key.pem'
  end

  # Generate Passkey for encrypting tokens
  execute 'Generating Hookshot Passkey' do
    command "openssl genpkey -out \"#{new_resource.host_path}/keys/hookshot.pem\" -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096; chmod 400 '#{new_resource.host_path}/keys/hookshot.pem'"
    user 'synapse'
    group 'synapse'
    sensitive true
    creates "#{new_resource.host_path}/keys/hookshot.pem"
  end

  # Generate the config file
  file "#{new_resource.host_path}/#{new_resource.container_name}-config.yaml" do
    content osl_yaml_dump(new_resource.config)
    owner 'synapse'
    group 'synapse'
    mode '400'
    sensitive true
  end

  # Generate the compose config
  config_compose = {
    'services' => {
      new_resource.container_name => {
        'image' => "halfshot/matrix-hookshot:#{new_resource.tag}",
        'ports' => [
          "#{new_resource.port_webhook}:#{new_resource.port_webhook}",
          "#{new_resource.port_metric}:#{new_resource.port_metric}",
          "#{new_resource.port_widget}:#{new_resource.port_widget}",
        ],
        'volumes' => [
          "#{new_resource.host_path}/appservice/#{new_resource.container_name}.yaml:/data/registration.yml",
          "#{new_resource.host_path}/#{new_resource.container_name}-config.yaml:/data/config.yml",
          "#{new_resource.host_path}/keys/hookshot.pem:/data/keys/hookshot.pem",
          "#{new_resource.host_path}/keys/github-key.pem:/data/keys/github-key.pem",
        ],
        'user' => osl_synapse_user,
        'restart' => 'always',
        'networks' => [
          compose_name,
        ],
      },
    },
    'networks' => {
      compose_name => {
        'external' => true,
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
