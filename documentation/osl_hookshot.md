# osl\_hookshot

A Matrix appservice which allows for creating and deploying webhooks into rooms.

**IMPORTANT**: Appservice resources should only be called *after* deploying the Matrix Synapse Server.

## Actions

| Action   | Description     |
| -------- | --------------- |
| `create` | Deploy Hookshot |

## Properties

| Name             | Type    | Default                                       | Description | Required |
| ---------------- | ------- | --------------------------------------------- | ----------- | -------- |
| `config`         | Hash    |                                               | General Matrix Hookshot settings to apply, mostly going to be used to set up specific services and configuration permissions. A lot of other required configurations have been automated. Information of arguments can be found in the [Hookshot Documentation](https://matrix-org.github.io/matrix-hookshot/latest/setup/sample-configuration.html) | |
| `container_name` | String  |                                               | The name of the Docker container running Hookshot. Use this name for specifiying the appservices available on a `osl_synapse` service | Yes, name property |
| `port`           | Integer | `9993`                                        | The port used for internal listening from requests from the Matrix Synapse server | |
| `port_webhook`   | Integer | `9000`                                        | **IMPORTANT, SECURITY** The port open on the host machine which listens for HTTP requests. More information can be found in the [Hookshot Documentation](https://matrix-org.github.io/matrix-hookshot/latest/setup/webhooks.html). It's recommended to put this behind a reverse proxy | |
| `port_metric`    | Integer | `9001`                                        | **IMPORTANT, SECURITY** The port open on the host machine which listens for HTTP requests specifically for the Prometheus standard. More information can be found in the [Hookshot Documentation](https://matrix-org.github.io/matrix-hookshot/latest/metrics.html). It's recommended to put this behind a reverse proxy | |
| `port_widget`    | Integer | `9002`                                        | **IMPORTANT, SECURITY** The port open on the host machine which is an experimental feature only available on Synapse servers which allows for using Hookshot as a Widget. More information can be found in the [Hookshot Documentation](https://matrix-org.github.io/matrix-hookshot/latest/advanced/widgets.html). It's recommended to put this behind a reverse proxy | |
| `host_domain`    | String  |                                               | The resource name of the Matrix Synapse Server Hookshot will be providing for | Yes |
| `host_name`      | String  | `matrix-synapse-{host_domain}`                | The name of the Docker container containing the Matrix Synapse server | |
| `host_network`   | String  | `synapse-network-{host_name}`                 | The name of the Docker network in which the Matrix Synapse server, and this appservice, will be attached | |
| `host_path`      | String  | `/opt/synapse-{host_name}`                    | The path to the configuration files of the Matrix Synapse server  | |
| `key_appservice` | String  | `MD5 hash of host_name and container_name`    | **IMPORTANT, SECURITY** A string token that the appservices uses to authenticate requests to the homeserver. Please change out with a databag entry | Encouraged |
| `key_homeserver` | String  | `MD5 hash of host_network and container_name` | **IMPORTANT, SECURITY** A string token that the homesever uses to authenticate requests to the appservice. Please change out with a databag entry | Encouraged |

## Examples
```ruby
# Deploy Hookshot with only a generic webhook onto chat.example.org
osl_synapse 'chat.example.org' do
  app_services: %w(example-hookshot)
end

osl_hookshot 'example-hookshot' do
  host_domain 'chat.example.org'
  config({
    'generic': {
      'enabled': true,
      'urlPrefix': 'http://chat.example.org/webhook',
      'userIdPrefix': 'example-hook'
    }
  })
end
```
