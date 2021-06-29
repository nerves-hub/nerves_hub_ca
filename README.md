# NervesHubCA

[![CircleCI](https://circleci.com/gh/nerves-hub/nerves_hub_ca.svg?style=svg)](https://circleci.com/gh/nerves-hub/nerves_hub_ca)

NervesHub Certificate Authority is used to generate certificates for representing
trusted device connections to the NervesHub API. The certificate authority
application should be run disconnected from the public internet and only
interface with other trusted servers.

# Certificate Chain Structure
```
                   --------------
                  |   Root CA    |
                   --------------
                /         |        \
 --------------    --------------    --------------
| Intermediate |  | Intermediate |  | Intermediate |
|   User CA    |  |  Device CA   |  |  Server CA   | 
 --------------    --------------    --------------
       |                  |                 |        \
 --------------    --------------    --------------    ---------------
|     User     |  |    Device    |  |    Server    |  |   CA Client   |
|  Certificate |  |  Certificate |  |  Certificate |  |  Certificate  |
 --------------    --------------    --------------    ---------------
```

## Initial development environment setup

Generate initial certificates

```bash
mix nerves_hub_ca.init
```

This will generate the initial certificate chain and place it in `{cwd}/etc/ssl`.
You can specify a different location by passing the `--path` option:

```bash
mix nerves_hub_ca.init --path /tmp
```

## Configuration

`NervesHubCA` is configured to use certs and keys generated in the default locations. If you specified a custom location with `--path` or `NERVES_HUB_CA_DIR`, then you will need to update your config for the API:

```elixir
working_dir = "/your/custom/path"

config :nerves_hub_ca, :api,
  cacertfile: Path.join(working_dir, "ca.pem"),
  certfile: Path.join(working_dir, "ca.nerves-hub.org.pem"),
  keyfile: Path.join(working_dir, "ca.nerves-hub.org-key.pem")

config :nerves_hub_ca, CA.User,
  ca: Path.join(working_dir, "user-root-ca.pem"),
  ca_key: Path.join(working_dir, "user-root-ca-key.pem")

config :nerves_hub_ca, CA.Device,
  ca: Path.join(working_dir, "device-root-ca.pem"),
  ca_key: Path.join(working_dir, "device-root-ca-key.pem")
```

All options under the config keys `:nerves_hub_ca, :api` are passed through when configuring `:cowboy`. So if you need to change HTTP specific settings, such as the port (which is defaulted to `8443`), you can add it to the config:

```elixir
config :nerves_hub_ca, :api, 
  port: 8443
```

For added security, you can enable client SSL and limit requests to only trusted servers.

```elixir
config :nerves_hub_ca, :api,
  port: 8443,
  verify: :verify_peer,
  fail_if_no_peer_cert: true
```

# API

* Route: `/health_check`
  * Method: **GET**
  * Response: 200 OK
    
* Route: `/sign_device_csr`
  * Method: **POST**
  * Parameters:
    * `csr`: Binary certificate signing request for the device

  * Response Parameters
    * `cert`: The certificate pem
    * `issuer`: The issuer pem
    * `error`: Present if any error occurred during processing

* Route: `/sign_user_csr`
  * Method: **POST**
  * Parameters:
    * `csr`: Binary certificate signing request for the device

  * Response Parameters
    * `cert`: The certificate pem
    * `issuer`: The issuer pem
    * `error`: Present if any error occurred during processing

# Tests

The NervesHubCA test suite will create a certificate authority and generate a
trusted CA API certificate before running any of the tests. Dependents can bring
up a clean CA by altering the mix aliases.

```elixir
# mix.exs
#...
  def project do
    [
      #...
      aliases: [test: ["nerves_hub_ca.init", "test"]]
    ]
  end
#...
```

## Building for a private installation

Building the application for an alternative host will require setting the environment
variable `NERVES_HUB_HOST`. This will default to `nerves-hub.org`. You should set this
to the web host for your domain.
