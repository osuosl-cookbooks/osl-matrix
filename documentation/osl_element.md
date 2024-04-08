# osl\_element

A simple resource that sets up and deploys the Matrix Element web-application, along with configuring the webapp to automatically attempt to login to a specified Matrix server.

**WARNING**: This resource is not responsible for setting up a secure web environment, please look into implementing `osl-apache` in your recipe to act as a reverse proxy.

## Actions

| Action   | Description                      |
| -------- | -------------------------------- |
| `create` | Deploy the Matrix Element webapp |

## Properties

| Name            | Type    | Default | Description                                       |
| --------------- | ------- | ------- | ------------------------------------------------- |
| `matrix_domain` | String  | `nil`   | The FQDN of the matrix server to default login to |
| `port`          | Integer | `8000`  | The port to listen on for HTTP requests.          |

## Examples
```ruby
# Host an Element site for chat.example.org
osl_element 'chat.example.org'

# Host an Element site for chat.example.org on port 9000
osl_element 'chat.example.org' do
  port 9000
end
```
