# osl\_synapse\_admin

Deploys [Ketesa](https://github.com/etkecc/ketesa) (`etkecc/ketesa`), the maintained fork of Synapse Admin, as an admin
web-interface for a Matrix Synapse server. The container's static web server listens on 8080 and is published on
`port`; `config.json` is written to `/opt/synapse_admin_<container_name>/config.json` and mounted read-only at
`/var/public/config.json`.

**NOTE**: Ketesa talks to the homeserver from the browser, so `/_synapse/admin` must be reachable from wherever the admins
use it.

**WARNING**: This resource is not responsible for setting up a secure web environment; put a reverse proxy (such as
`osl-apache` or the load balancers) in front of it.

## Actions

| Action   | Description               |
| -------- | ------------------------- |
| `create` | Deploy the Ketesa webapp  |

## Properties

| Name             | Type            | Default            | Description                                                                                                                        |
| ---------------- | --------------- | ------------------ | ---------------------------------------------------------------------------------------------------------------------------------- |
| `container_name` | String          | name property      | Name of the container and of its config directory                                                                                  |
| `home_server`    | String or Array | `nil`              | Homeserver URL(s) Ketesa is locked to (`restrictBaseUrl`)                                                                           |
| `port`           | Integer         | `8080`             | Host port to publish the webapp on                                                                                                 |
| `tag`            | String          | `v1`               | `etkecc/ketesa` image tag. `v1` follows the 1.x releases; `latest` is the nightly build of main                                    |
| `config`         | Hash            | `{}`               | Other [Ketesa settings](https://github.com/etkecc/ketesa/blob/main/docs/config.md) for `config.json`, such as `asManagedUsers`     |

`config.json` holds `config` plus `restrictBaseUrl` from `home_server`; when both are empty, no file is written and the
image's own defaults apply.

## Examples

```ruby
# Ketesa for matrix.example.org on port 8000
osl_synapse_admin 'synapse_admin' do
  home_server 'https://matrix.example.org'
  port 8000
end

# Pinned to one release, with the bridge accounts protected from edits
osl_synapse_admin 'synapse_admin' do
  home_server 'https://matrix.example.org'
  port 8000
  tag 'v1.5.2'
  config('asManagedUsers' => ['^@irc_.*:example.org$', '^@hookshot:example.org$'])
end
```
