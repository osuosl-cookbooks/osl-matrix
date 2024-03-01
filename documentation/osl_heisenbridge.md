# osl\_heisenbridge

A Matrix appservice which allows for bridging IRC chat messages.

**IMPORTANT**:
* Appservice resources should only be called *after* deploying the Matrix Synapse Server.
* This resource will not deploy, by itself. It requires an [`osl_dockercompose`](https://github.com/osuosl-cookbooks/osl-docker/blob/master/resources/dockercompose.rb) resource.

## Actions

| Action   | Description         |
| -------- | ------------------- |
| `create` | Deploy Heisenbridge |

## Properties

| Name             | Type    | Default                                       | Description | Required |
| ---------------- | ------- | --------------------------------------------- | ----------- | -------- |
| `container_name` | String  |                                               | The name of the Docker container running Heisenbridge. Use this name for specifiying the appservices available on a `osl_synapse` service | Yes, name property |
| `port`           | Integer | `9898`                                        | The port used for internal listening from requests from the Matrix Synapse server | |
| `host_domain`    | String  |                                               | The resource name of the Matrix Synapse Server Heisenbridge will be providing for | Yes |
| `host_name`      | String  | `matrix-synapse-{host_domain}`                | The name of the Docker container containing the Matrix Synapse server | |
| `host_network`   | String  | `synapse-network-{host_name}`                 | The name of the Docker network in which the Matrix Synapse server, and this appservice, will be attached | |
| `host_path`      | String  | `/opt/synapse-{host_name}`                    | The path to the configuration files of the Matrix Synapse server  | |
| `key_appservice` | String  | `MD5 hash of host_name and container_name`    | **IMPORTANT, SECURITY** A string token that the appservices uses to authenticate requests to the homeserver. Please change out with a databag entry | Encouraged |
| `key_homeserver` | String  | `MD5 hash of host_network and container_name` | **IMPORTANT, SECURITY** A string token that the homesever uses to authenticate requests to the appservice. Please change out with a databag entry | Encouraged |
| `tag`            | String  | `latest`                                      | The Heisenbridge version to deploy. Please view the [Docker Hub](https://hub.docker.com/r/hif1/heisenbridge) for valid entries. | |

## Examples
```ruby
# Deploy Heisenbridge onto chat.example.org
osl_synapse 'chat.example.org' do
  appservices: %w(example-heisenbridge)
end

osl_heisenbridge 'example-heisenbridge' do
  host_domain 'chat.example.org'
end
```
