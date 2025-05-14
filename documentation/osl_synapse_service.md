# osl\_synapse\_service

A wrapper resource to quickly deploy a Matrix Synapse server, with available appservices, without needing extra resources.

**WARNING**: This resource is not responsible for setting up a secure web environment, please look into implementing `osl-apache` in your recipe to act as a reverse proxy.

Any missing properties with the `pg_` prefix will result in the server setting up an SQLite database. This database type is not recommended for deployments.

## Actions

| Action   | Description                       |
| -------- | --------------------------------- |
| `create` | Deploy the Matrix Synapse server  |

## Available Appservices

| Appservice     | Description                                                                 |
| -------------- | --------------------------------------------------------------------------- |
| `heisenbridge` | An IRC bridge for Matrix [\[Github\]](https://github.com/hifi/heisenbridge) |
| `hookshot`     | A webhook bot for recieving alerts [\[Github\]](https://github.com/matrix-org/matrix-hookshot) |
| `matrix-appservice-irc` | A more feature rich IRC bridge for Matrix [\[Github\]](https://github.com/matrix-org/matrix-appservice-irc) |
| `mjolnir`      | An auto-moderation bot for Matris [\[Github\]](https://github.com/matrix-org/mjolnir) |

## Properties

| Name             | Type             | Default                                          | Description | Required |
| ---------------- | ---------------- | ------------------------------------------------ | ----------- | -------- |
| `appservices`    | Array            | `[]`                                             | An array of appservices which will be tied to this application. **Provide the resource name of the appservice**. | |
| `config`         | Hash             | `{}`                                             | General Matrix Synapse settings to apply. Information of arguments can be found in the [Synapse Documentation](https://matrix-org.github.io/synapse/latest/usage/configuration/config_documentation.html) | |
| `config_hookshot`| Hash             |                                                  | General Matrix Hookshot settings to apply, mostly going to be used to set up specific services and configuration permissions. A lot of other required configurations have been automated. Information of arguments can be found in the [Hookshot Documentation](https://matrix-org.github.io/matrix-hookshot/latest/setup/sample-configuration.html) | |
| `config_mjolnir` | Hash             |                                                  | A grainular application to Mjolnir settings. A lot of other required configurations have been automated. Information of arguments can be found in the [Mjolnir Example](https://github.com/matrix-org/mjolnir/blob/main/src/appservice/config/config.example.yaml) | |
| `domain`         | String           |                                                  | The FQDN of the matrix synapse site | Yes, resource name |
| `pg_host`        | String           |                                                  | IP/Hostname of the Postgresql server | |
| `pg_name`        | String           |                                                  | Database name | |
| `pg_username`    | String           |                                                  | Username for connecting to the PostgreSQL server | |
| `pg_password`    | String           |                                                  | Password for authenticating to the PostgreSQL server | |
| `port`           | Integer          | `8008`                                           | The port which the Matrix Synapse server will listen on for web traffic | |
| `reg_key`        | String           | `MD5 hash of container_name, network, and path`  | **IMPORTANT, SECURITY** A random string which is used for registering accounts, whenever and whererver. Admin or standard user. We advise you set this with a databag entry | Encouraged |
| `tag`            | String           | `latest`                                         | The Matrix Synapse version to deploy. Please view the [Docker Hub](https://hub.docker.com/r/matrixdotorg/synapse/tags) for valid entries. | |
| `tag_heisenbridge`| String          | `latest`                                         | The Heisenbridge version to deploy. Please view the [Docker Hub](https://hub.docker.com/r/hif1/heisenbridge) for valid entries. | |
| `tag_hookshot`   | String           | `latest`                                         | The Hookshot version to deploy. Please view the [Docker Hub](https://hub.docker.com/r/halfshot/matrix-hookshot) for valid entries. | |

## Examples
```ruby
# Host a basic Synapse server, with a PostgreSQL server located on the same VM
osl_synapse_service 'chat.example.org' do
  pg_host: '127.0.0.1'
  pg_name: 'synapse-data'
  pg_username: 'synapse-user'
  pg_password: 'password'
end

# Synapse server with image embeding enabled, an increased file upload size, and Heisenbridge
osl_synapse_service 'chat.example.org' do
  appservices %w(heisenbridge)
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
