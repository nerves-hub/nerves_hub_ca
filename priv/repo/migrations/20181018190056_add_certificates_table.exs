defmodule NervesHubCA.Repo.Migrations.AddCertificatesTable do
  use Ecto.Migration

  def change do
    create table("certificates") do
      add :serial, :string
      add :aki, :binary
      add :ski, :binary
      add :expiry, :utc_datetime
      add :pem, :text
      add :revoked_at, :utc_datetime
      add :reason, :integer

      timestamps()
    end

    create index("certificates", [:serial], unique: true)
  end
end
