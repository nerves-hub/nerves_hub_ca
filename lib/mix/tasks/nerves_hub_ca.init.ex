defmodule Mix.Tasks.NervesHubCa.Init do
  alias NervesHubCA.CertificateTemplate

  @path Path.join(File.cwd!(), "etc/cfssl")

  @switches [
    path: :string
  ]

  def run(args) do
    {opts, _args} = OptionParser.parse!(args, strict: @switches)

    path = opts[:path] || Application.get_env(:nerves_hub_ca, :working_dir) || @path

    File.mkdir_p(path)

    # Generate Self-Signed Root
    {root_ca, root_ca_key} = gen_root_ca_cert("NervesHub Root CA")

    write_certs(root_ca, root_ca_key, "root-ca", path)

    # Generate Org certs
    {org_root_ca, org_root_ca_key} =
      gen_int_ca_cert(root_ca, root_ca_key, "NervesHub Org Root CA", 1)

    {org1_ca, org1_ca_key} =
      gen_int_ca_cert(org_root_ca, org_root_ca_key, "NervesHub Org1 CA", 0)

    write_certs(org_root_ca, org_root_ca_key, "org-root-ca", path)
    write_certs(org1_ca, org1_ca_key, "org1-ca", path)

    # Generate User certs
    {user_root_ca, user_root_ca_key} =
      gen_int_ca_cert(root_ca, root_ca_key, "NervesHub User Root CA", 0)

    write_certs(user_root_ca, user_root_ca_key, "user-root-ca", path)

    # Generate Server certs
    {server_root_ca, server_root_ca_key} =
      gen_int_ca_cert(root_ca, root_ca_key, "NervesHub Server Root CA", 0)

    {ca_server, ca_server_key} =
      gen_server_cert(server_root_ca, server_root_ca_key, "NervesHub CA Server", [
        "ca.nerves-hub.org"
      ])

    {api_server, api_server_key} =
      gen_server_cert(server_root_ca, server_root_ca_key, "NervesHub API Server", [
        "api.nerves-hub.org"
      ])

    {device_server, device_server_key} =
      gen_server_cert(server_root_ca, server_root_ca_key, "NervesHub Device Server", [
        "device.nerves-hub.org"
      ])

    write_certs(server_root_ca, server_root_ca_key, "server-root-ca", path)
    write_certs(ca_server, ca_server_key, "ca.nerves-hub.org", path)
    write_certs(api_server, api_server_key, "api.nerves-hub.org", path)
    write_certs(device_server, device_server_key, "device.nerves-hub.org", path)

    ca_bundle_path = Path.join(path, "ca.pem")

    ca_bundle =
        X509.Certificate.to_pem(root_ca) <> X509.Certificate.to_pem(user_root_ca) <>
        X509.Certificate.to_pem(server_root_ca) <> X509.Certificate.to_pem(org_root_ca)

    File.write(ca_bundle_path, ca_bundle)
  end

  defp gen_server_cert(issuer, issuer_key, common_name, subject_alt_names) do
    opts = [
      hash: CertificateTemplate.hash(),
      validity: NervesHubCA.CertificateTemplate.years(3),
      extensions: [
        subject_alt_name: X509.Certificate.Extension.subject_alt_name(subject_alt_names)
      ]
    ]

    X509.Certificate.Template.new(:server, opts)
    |> gen_cert(issuer, issuer_key, common_name)
  end

  defp gen_int_ca_cert(issuer, issuer_key, common_name, path_length) do
    opts = [
      serial: CertificateTemplate.random_serial_number(),
      validity: NervesHubCA.CertificateTemplate.years(10),
      hash: CertificateTemplate.hash(),
      extensions: [
        basic_constraints: X509.Certificate.Extension.basic_constraints(true, path_length),
        ext_key_usage: false
      ]
    ]

    X509.Certificate.Template.new(:ca, opts)
    |> gen_cert(issuer, issuer_key, common_name)
  end

  defp gen_root_ca_cert(common_name) do
    opts = [
      serial: CertificateTemplate.random_serial_number(),
      validity: NervesHubCA.CertificateTemplate.years(30),
      hash: CertificateTemplate.hash(),
      extensions: [
        key_usage: X509.Certificate.Extension.key_usage([:keyCertSign, :cRLSign]),
        basic_constraints: X509.Certificate.Extension.basic_constraints(true),
        subject_key_identifier: true,
        authority_key_identifier: false
      ]
    ]

    template = X509.Certificate.Template.new(:root_ca, opts)
    ca_key = X509.PrivateKey.new_ec(CertificateTemplate.ec_named_curve())
    subject_rdn = Path.join(CertificateTemplate.subject_rdn(), "CN=" <> common_name)
    ca = X509.Certificate.self_signed(ca_key, subject_rdn, template: template)
    {ca, ca_key}
  end

  defp gen_cert(template, issuer, issuer_key, common_name) do
    private_key = X509.PrivateKey.new_ec(CertificateTemplate.ec_named_curve())
    public_key = X509.PublicKey.derive(private_key)
    subject_rdn = Path.join(CertificateTemplate.subject_rdn(), "CN=" <> common_name)
    ca = X509.Certificate.new(public_key, subject_rdn, issuer, issuer_key, template: template)
    {ca, private_key}
  end

  defp write_certs(cert, private_key, name, path) do
    cert = X509.Certificate.to_pem(cert)
    private_key = X509.PrivateKey.to_pem(private_key)

    cert_path = Path.join(path, "#{name}.pem")
    File.write!(cert_path, cert)

    private_key_path = Path.join(path, "#{name}-key.pem")
    File.write!(private_key_path, private_key)
  end
end
