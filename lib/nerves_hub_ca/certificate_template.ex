defmodule NervesHubCA.CertificateTemplate do
  import X509.Certificate.Extension
  alias X509.Certificate.{Template, Validity}

  @user_validity_years 1
  @device_validity_years 5

  @hash :sha256
  @ec_named_curve :secp256r1
  @subject_rdn "/C=US/ST=MD/L=Rockville/O=NervesHub"

  def hash(), do: @hash
  def ec_named_curve(), do: @ec_named_curve

  def subject_rdn(), do: @subject_rdn
  def user_subject_rdn(), do: Path.join(@subject_rdn, "CN=NervesHub User Certificate")
  def device_subject_rdn(), do: Path.join(@subject_rdn, "CN=NervesHub Device Certificate")

  def user() do
    %Template{
      validity: years(@user_validity_years),
      hash: @hash,
      extensions: [
        basic_constraints: basic_constraints(false),
        key_usage: key_usage([:digitalSignature, :keyEncipherment]),
        ext_key_usage: ext_key_usage([:clientAuth]),
        subject_key_identifier: true,
        authority_key_identifier: true
      ]
    }
    |> Template.new()
  end

  def device() do
    %Template{
      validity: years(@device_validity_years),
      hash: @hash,
      extensions: [
        basic_constraints: basic_constraints(false),
        key_usage: key_usage([:digitalSignature, :keyEncipherment]),
        ext_key_usage: ext_key_usage([:clientAuth]),
        subject_key_identifier: true,
        authority_key_identifier: true
      ]
    }
    |> Template.new()
  end

  # Helpers

  defp years(years) do
    now =
      DateTime.utc_now()
      |> trim()

    not_before = backdate(now, 1) |> trim()
    not_after = Map.put(now, :year, now.year + years)
    Validity.new(not_before, not_after)
  end

  defp backdate(datetime, hours) do
    datetime
    |> DateTime.to_unix()
    |> Kernel.-(hours * 60 * 60)
    |> DateTime.from_unix!()
  end

  defp trim(datetime) do
    datetime
    |> Map.put(:minute, 0)
    |> Map.put(:second, 0)
    |> Map.put(:microsecond, {0, 0})
  end
end
