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
    |> validate_url_format()
    |> unique_constraint(:short_code)
  end

  defp validate_url_format(changeset) do
    changeset
    |> validate_format(:original_url, ~r/^https?:\/\/.+/i,
      message: "must be a valid URL starting with http:// or https://"
    )
    |> validate_length(:original_url, min: 10, max: 2048)
  end
end
