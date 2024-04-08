# osl\_synapse

Set up a Matrix Synapse server, and configure the server.

**WARNING**:
* This resource is not responsible for setting up a secure web environment, please look into implementing `osl-apache` in your recipe to act as a reverse proxy.
* This resource will not deploy, by itself. It requires an [`osl_dockercompose`](https://github.com/osuosl-cookbooks/osl-docker/blob/master/resources/dockercompose.rb) resource.

Any missing properties with the `pg_` prefix will result in the server setting up an SQLite database. This database type is not recommended for deployments.

## Actions

| Action   | Description                       |
| -------- | --------------------------------- |
| `create` | Deploy the Matrix Synapse server  |

## Properties

| Name             | Type             | Default                                          | Description | Required |
| ---------------- | ---------------- | ------------------------------------------------ | ----------- | -------- |
| `appservices`    | Array            | `[]`                                             | An array of appservices which will be tied to this application. **Provide the resource name of the appservice**. | |
| `config`         | Hash             | `{}`                                             | General Matrix Synapse settings to apply. Information of arguments can be found in the [Synapse Documentation](https://matrix-org.github.io/synapse/latest/usage/configuration/config_documentation.html) | |
| `container_name` | String           | `synapse-{domain}`                        | The name of the Docker container containing the Matrix Synapse server | |
| `domain`         | String           |                                                  | The FQDN of the matrix synapse site | Yes, resource name |
| `path`           | String           | `/opt/{container_name}`                  | The path to the configuration files of the Matrix Synapse server | |
| `pg_host`        | String           |                                                  | IP/Hostname of the Postgresql server | |
| `pg_name`        | String           |                                                  | Database name | |
| `pg_username`    | String           |                                                  | Username for connecting to the PostgreSQL server | |
| `pg_password`    | String           |                                                  | Password for authenticating to the PostgreSQL server | |
| `port`           | Integer          | `8008`                                           | The port which the Matrix Synapse server will listen on for web traffic | |
| `reg_key`        | String           | `MD5 hash of container_name, network, and path`  | **IMPORTANT, SECURITY** A random string which is used for registering accounts, whenever and whererver. Admin or standard user. We advise you set this with a databag entry | Encouraged |
| `tag`            | String           | `latest`                                         | The Matrix Synapse version to deploy. Please view the [Docker Hub](https://hub.docker.com/r/matrixdotorg/synapse/tags) for valid entries. | |

## Examples
```ruby
# Host a basic Synapse server, with a PostgreSQL server located on the same VM
osl_synapse 'chat.example.org' do
  pg_host: '127.0.0.1'
  pg_name: 'synapse-data'
  pg_username: 'synapse-user'
  pg_password: 'password'
end

# Synapse server with image embeding enabled and an increased file upload size
osl_synapse 'chat.example.org' do
  config({
    'max_upload_size': '1G',
    'url_preview_enabled': true,
    'url_preview_ip_range_blacklist': [
      '127.0.0.0/8',
      '10.0.0.0/8'
    ]
  })
end
```
