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

## Initial development environment setup

Start an iex shell and generate the ca root certificates and 
api web server certificates:

```elixir
iex> path = NervesHubCA.Storage.working_dir()
iex> NervesHubCA.InitHelper.init_ca(path)
iex> NervesHubCA.InitHelper.init_api(path)
```

Finally, configure the `:nerves_hub_ca` application with the location of the
certificates. For example: 

```elixir
# config/config.exs

working_dir = Path.join(File.cwd!, "etc/cfssl")
if File.dir?(working_dir) do
  config :nerves_hub_ca, :api, 
    cacertfile: Path.join(working_dir, "ca.pem"),
    certfile: Path.join(working_dir, "ca-api.pem"),
    keyfile: Path.join(working_dir, "ca-api-key.pem")
end
```

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

* Route: `/device`
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
up a clean CA by adding `NervesHubCA.InitHelper.start()` to the `test/test_helper.exs`
file. 

See `test/support/init_helper.ex` for more information.
