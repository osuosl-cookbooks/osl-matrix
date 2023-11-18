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
property :port_host, Integer, default: 8008
property :host_domain, String, required: true
property :host_name, String, default: lazy { "matrix-synapse-#{host_domain}" }
property :host_path, String, default: lazy { "/opt/synapse-#{host_name}" }
property :host_network, String, default: lazy { "synapse-network-#{host_name}" }
property :key_appservice, String, default: lazy { osl_matrix_genkey(host_name + container_name) }
property :key_homeserver, String, default: lazy { osl_matrix_genkey(host_network + container_name) }

action :create do
  # Pull down the Hookshot image
  docker_image 'halfshot/matrix-hookshot'

  # Parse out all of the instance of userIdPrefix in order to modify the appservice registration
  arrAppServiceUsers = []
  # Loop over the root hash
  new_resource.config.each_value do |val|
    # Check to see if the sub-hash has a key called userIDPrefix
    unless val.is_a?(Hash) && val.key?('userIdPrefix')
      next
    end
    # Add the userIDPrefix
    arrAppServiceUsers.push({
      exclusive: true,
      regex: "\'@#{val['userIdPrefix']}_.*\'",
    })
  end

  # Add in something if there was nothing given
  unless arrAppServiceUsers
    arrAppServiceUsers.push({
      exclusive: true,
      regex: '\'@webhook_.*\'',
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
      users: arrAppServiceUsers,
    }
  )

  # Auto configuration for the homeserver, ignore if already set
  # Passkey settings
  # Not usually needed to be modified by user, as we generate our own, but just in case.
  new_resource.config.merge!({
    'passFile' => '/data/hookshot.pem',
  }) { |_key, old_value, new_value| old_value || new_value }

  # Bridge settings
  # Ensure the bridge key hash exists
  new_resource.config['bridge'] = {} unless new_resource.config['bridge']
  new_resource.config['bridge'].merge!({
    'domain' => new_resource.host_domain,
    'url' => "http://#{new_resource.host_name}:#{new_resource.port_host}",
    'port' => new_resource.port,
    'bindAddress' => '0.0.0.0',
  }) { |_key, old_value, new_value| old_value || new_value }

  # Listeners settings
  # Force the automatically generated configuration, custom config goes against the spirit of some properties.
  if new_resource.config['listeners']
    # Get the information about where the resource is declared, and tell the developer that there will be changes to the defined key.
    pResource = find_resource(:osl_hookshot, new_resource.container_name)
    log 'Checking for overwriting custom configuration' do
      message "#{pResource.source_line}: Any definitions within the listeners key will be overwritten by the resource. Please read documentation for more information."
      level :warn
    end
  end

  new_resource.config['listeners'] = [
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

  # Generate Passkey for encrypting tokens
  execute 'Generating Hookshot Passkey' do
    command "openssl genpkey -out \"#{new_resource.host_path}/keys/hookshot.pem\" -outform PEM -algorithm RSA -pkeyopt rsa_keygen_bits:4096"
    user 'synapse'
    creates "#{new_resource.host_path}/keys/hookshot.pem"
  end

  # Generate the config file
  file "#{new_resource.host_path}/#{new_resource.container_name}-config.yaml" do
    content YAML.dump(new_resource.config).lines[1..-1].join
    owner 'synapse'
    group 'synapse'
    mode '770'
    sensitive true
  end

  # Determine if we should have the metric port open
  # Create the docker container
  docker_container new_resource.container_name do
    repo 'halfshot/matrix-hookshot'
    volumes [
      "#{new_resource.host_path}/#{new_resource.container_name}.yaml:/data/registration.yml",
      "#{new_resource.host_path}/#{new_resource.container_name}-config.yaml:/data/config.yml",
      "#{new_resource.host_path}/keys/hookshot.pem:/data/hookshot.pem",
    ]
    port [
      "#{new_resource.port_webhook}:#{new_resource.port_webhook}",
      "#{new_resource.port_metric}:#{new_resource.port_metric}",
      "#{new_resource.port_widget}:#{new_resource.port_widget}",
    ]
    restart_policy 'always'
  end

  # Connect to the network
  docker_network new_resource.host_network do
    container new_resource.container_name
    action :connect
  end
end
