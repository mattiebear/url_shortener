defmodule TinyUrl.Links.Link do
  use Ecto.Schema
  import Ecto.Changeset

  schema "links" do
    field :original_url, :string
    field :short_code, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(link, attrs) do
    link
    |> cast(attrs, [:original_url])
    |> validate_required([:original_url])
  end
end
