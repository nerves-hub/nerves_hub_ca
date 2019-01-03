defmodule NervesHubCA.Certificate do
  use Ecto.Schema

  import X509.ASN1,
    only: [extension: 1, authority_key_identifier: 1, validity: 1]

  @era 2000

  @required_params [
    :serial,
    :aki,
    :ski,
    :pem,
    :expiry
  ]

  @optional_params [
    :revoked_at,
    :reason
  ]

  schema "certificates" do
    field(:serial, :string)
    field(:aki, :binary)
    field(:ski, :binary)
    field(:pem, :string)
    field(:expiry, :utc_datetime)
    field(:reason, :integer)
    field(:revoked_at, :utc_datetime)

    timestamps()
  end

  def changeset(certificate, params \\ %{}) do
    certificate
    |> Ecto.Changeset.cast(params, @required_params ++ @optional_params)
    |> Ecto.Changeset.validate_required(@required_params)
    |> Ecto.Changeset.unique_constraint(:serial)
  end

  def encode_aki(otp_certificate) do
    otp_certificate
    |> X509.Certificate.extensions()
    |> X509.Certificate.Extension.find(:authority_key_identifier)
    |> extension()
    |> Keyword.get(:extnValue)
    |> authority_key_identifier()
    |> Keyword.get(:keyIdentifier)
  end

  def encode_ski(otp_certificate) do
    otp_certificate
    |> X509.Certificate.extensions()
    |> X509.Certificate.Extension.find(:subject_key_identifier)
    |> extension()
    |> Keyword.get(:extnValue)
  end

  def encode_expiry(otp_certificate) do
    {type, timestamp} =
      X509.Certificate.validity(otp_certificate)
      |> validity()
      |> Keyword.get(:notAfter)

    {type, to_string(timestamp)}
    |> convert_timestamp
  end

  defp convert_timestamp({:utcTime, timestamp}) do
    <<year::binary-unit(8)-size(2), month::binary-unit(8)-size(2), day::binary-unit(8)-size(2),
      hour::binary-unit(8)-size(2), minute::binary-unit(8)-size(2),
      second::binary-unit(8)-size(2), "Z">> = timestamp

    NaiveDateTime.new(
      String.to_integer(year) + @era,
      String.to_integer(month),
      String.to_integer(day),
      String.to_integer(hour),
      String.to_integer(minute),
      String.to_integer(second)
    )
    |> case do
      {:ok, naive_date_time} ->
        DateTime.from_naive!(naive_date_time, "Etc/UTC")

      error ->
        error
    end
  end

  defp convert_timestamp({:generalTime, timestamp}) do
    <<year::binary-unit(8)-size(4), month::binary-unit(8)-size(2), day::binary-unit(8)-size(2),
      hour::binary-unit(8)-size(2), minute::binary-unit(8)-size(2),
      second::binary-unit(8)-size(2), "Z">> = timestamp

    NaiveDateTime.new(
      String.to_integer(year),
      String.to_integer(month),
      String.to_integer(day),
      String.to_integer(hour),
      String.to_integer(minute),
      String.to_integer(second)
    )
    |> case do
      {:ok, naive_date_time} ->
        DateTime.from_naive!(naive_date_time, "Etc/UTC")

      error ->
        error
    end
  end
end
