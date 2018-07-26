# NervesHubCA

[![CircleCI](https://circleci.com/gh/nerves-hub/nerves_hub_ca.svg?style=svg)](https://circleci.com/gh/nerves-hub/nerves_hub_ca)

NervesHub Certificate Authority is used to generate certificates for representing
trusted device connections to the NervesHub API. The certificate authority
application should be run disconnected from the public internet and only
interface with other trusted servers.

# Configuration

NervesHubCA requires that `cfssl` is installed.
Learn more about installing `cfssl` at https://github.com/cloudflare/cfssl

NervesHubCA will bring up a supervised instance of `cfssl` and attempt to start
a `cowboy2` HTTPS web server. Starting the web server requires that the `cfssl`
instance started with a ca certificate and a new certificate is generated.

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

This will generate the initial certificate chain and place it in `{cwd}/etc/cfssl`.
You can specify a different location by passing the `--path` option:

```bash
mix nerves_hub_ca.init --path /tmp
```

Finally, configure the `:nerves_hub_ca` application with the location of the
certificates. See the NervesHubCA config.exs for examples.

## Configuring the API webserver

All options under the config `:nerves_hub_ca` `:api` are passed through when
configuring `:cowboy`.

You will need to specify a port to run the web server on

```elixir
# config/config.exs

config :nerves_hub_ca, :api, 
  port: 8443
```

For added securing, you can enable client SSL and limit requests to only trusted
servers.

config :nerves_hub_ca, :api,
  port: 8443,
  verify: :verify_peer,
  fail_if_no_peer_cert: true

# API

* Route: `/create_device_certificate`
  * Method: `POST`
  * Parameters:
    * `serial`: The manufacture serial number.

    * Response Parameters
      * `certificate`: The certificate.
      * `certificate_request`: The certificate signing request.
      * `private_key`: The private key.
      * `sums`: Certificate checksums.

  * Route: `*`
    * All other matches are proxied to the cfssl instance.

Information about API endpoints can be found in the [CFSSL Docs](https://github.com/cloudflare/cfssl/tree/master/doc/api)

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
