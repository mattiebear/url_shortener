defmodule TinyUrl.Repo.Migrations.CreateLinks do
  use Ecto.Migration

  def change do
    create table(:links) do
      add :original_url, :text, null: false
      add :short_code, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:links, [:short_code])
  end
end
