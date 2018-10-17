defmodule NervesHubCA do
  alias NervesHubCA.CertificateTemplate
  alias NervesHubCA.Intermediate.CA

  @doc """
  Sign a device certificate.

  See the document:
  Generating and signing CSRs.md

  Parameters:
    `csr`: The binary certificate signing request
    `issuer`: The name of the issuer. This is used to link the certificate files.
  """
  @spec sign_device_csr(X509.CSR.t(), binary) :: {:ok, map} | {:error, any}
  def sign_device_csr(csr, issuer_name) do
    working_dir = NervesHubCA.Storage.working_dir()

    issuer = Path.join(working_dir, issuer_name <> ".pem")
    issuer_key = Path.join(working_dir, issuer_name <> "-key.pem")

    with true <- X509.CSR.valid?(csr),
         {:ok, {issuer, issuer_key}} <- load_issuer_pem(issuer, issuer_key) do
      public_key = X509.CSR.public_key(csr)
      template = CertificateTemplate.device()
      subject_rdn = CertificateTemplate.user_subject_rdn()

      cert = X509.Certificate.new(public_key, subject_rdn, issuer, issuer_key, template: template)

      {:ok,
       %{
         cert: X509.Certificate.to_pem(cert),
         issuer: X509.Certificate.to_pem(issuer)
       }}
    end
  end

  @doc """
  Sign a user certificate.

  The supplied certificate will contain the usrrname
  in the Organization of the Distinguished Name.

  See the document:
  Generating and signing CSRs.md

  Parameters:
    `csr`: A DER encoded certificate signing request
  """
  @spec sign_user_csr(X509.CSR.t()) :: {:ok, map} | {:error, any}
  def sign_user_csr(csr) do
    ca_opts = Application.get_env(:nerves_hub_ca, CA.User, [])
    issuer = ca_opts[:ca]
    issuer_key = ca_opts[:ca_key]

    with true <- X509.CSR.valid?(csr),
         {:ok, {issuer, issuer_key}} <- load_issuer_pem(issuer, issuer_key) do
      public_key = X509.CSR.public_key(csr)
      template = CertificateTemplate.user()
      subject_rdn = CertificateTemplate.user_subject_rdn()

      cert = X509.Certificate.new(public_key, subject_rdn, issuer, issuer_key, template: template)

      {:ok,
       %{
         cert: X509.Certificate.to_pem(cert),
         issuer: X509.Certificate.to_pem(issuer)
       }}
    end
  end

  defp load_issuer_pem(issuer, issuer_key) do
    with {:ok, issuer} <- File.read(issuer),
         {:ok, issuer} <- X509.Certificate.from_pem(issuer),
         {:ok, issuer_key} <- File.read(issuer_key),
         {:ok, issuer_key} <- X509.PrivateKey.from_pem(issuer_key) do
      {:ok, {issuer, issuer_key}}
    end
  end
end
