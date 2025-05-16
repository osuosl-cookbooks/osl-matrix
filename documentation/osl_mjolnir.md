# osl\_mjolnir

A Matrix auto-moderation appservice developed by the Matrix foundation.

[Mjolnir Documentation](https://github.com/matrix-org/mjolnir/blob/main/docs/setup.md)

**IMPORTANT**:
* Appservice resources should only be called *after* deploying the Matrix Synapse Server.
* This resource will not deploy, by itself. It requires an [`osl_dockercompose`](https://github.com/osuosl-cookbooks/osl-docker/blob/master/resources/dockercompose.rb) resource.
* This appservice **does not run by default**. It requires the creation of a channel, dictated by `default_channel`. Defaults to `#mjolnir`.

## Actions

| Action   | Description         |
| -------- | ------------------- |
| `create` | Deploy Mjolnir      |

## Properties

| Name             | Type    | Default                                       | Description | Required |
| ---------------- | ------- | --------------------------------------------- | ----------- | -------- |
| `config`         | Hash    |                                               | A grainular application to Mjolnir settings. A lot of other required configurations have been automated. Information of arguments can be found in the [Mjolnir Example](https://github.com/matrix-org/mjolnir/blob/main/src/appservice/config/config.example.yaml) | |
| `container_name` | String  |                                               | The name of the Docker container running Mjolnir. Use this name for specifiying the appservices available on a `osl_synapse` service | Yes, name property |
| `port`           | Integer | `9899`                                        | The port used for internal listening from requests from the Matrix Synapse server | |
| `port_api`       | Integer | `9004`                                        | **IMPORTANT, SECURITY** The port open on the host machine which listens for specific Matrix protocol HTTP requests. More information can be found in the [Mjolnir Documentation](https://github.com/matrix-org/mjolnir/blob/main/README.md#enabling-readable-abuse-reports). It's required to put this behind a reverse proxy | |
| `host_domain`    | String  |                                               | The resource name of the Matrix Synapse Server Mjolnir will be providing for | Yes |
| `host_name`      | String  | `matrix-synapse-{host_domain}`                | The name of the Docker container containing the Matrix Synapse server | |
| `host_path`      | String  | `/opt/synapse-{host_name}`                    | The path to the configuration files of the Matrix Synapse server  | |
| `key_appservice` | String  | `MD5 hash of host_name and container_name`    | **IMPORTANT, SECURITY** A string token that the appservices uses to authenticate requests to the homeserver. Please change out with a databag entry | Encouraged |
| `key_homeserver` | String  | `MD5 hash of host_network and container_name` | **IMPORTANT, SECURITY** A string token that the homesever uses to authenticate requests to the appservice. Please change out with a databag entry | Encouraged |
| `bot_name`       | String  | `Auto Mod`                                    | The fancy name of the bot | |
| `default_channel`| String  | `#mjolnir:{host_domain}`                      | The initial channel that Mjolnir connects to. The channel can be made private, after the bot connects. | |
| `tag`            | String  | `latest`                                      | The Mjolnir version to deploy. Please view the [Docker Hub](https://hub.docker.com/r/matrixdotorg/mjolnir) for valid entries. | |

## Examples
```ruby
# Deploy Mjolnir onto chat.example.org
osl_synapse 'chat.example.org' do
  appservices: %w(example-mod)
end

osl_mjolnir 'example-mod' do
  host_domain 'chat.example.org'
end
```
