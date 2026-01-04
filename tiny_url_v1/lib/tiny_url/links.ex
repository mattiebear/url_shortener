defmodule TinyUrl.Links do
  alias TinyUrl.Links.Link
  alias TinyUrl.Repo

  def get_link(id) do
    Repo.get(Link, id)
  end

  def change_link(%Link{} = link, attrs \\ %{}) when is_map(attrs) do
    Link.changeset(link, attrs)
  end

  def create_link(attrs \\ %{}) do
    %Link{}
    |> change_link(attrs)
    |> put_short_code()
    |> Repo.insert()
  end

  defp put_short_code(changeset) do
    if changeset.valid? do
      short_code = generate_unique_short_code()
      Ecto.Changeset.put_change(changeset, :short_code, short_code)
    else
      changeset
    end
  end

  defp generate_unique_short_code do
    code = :crypto.strong_rand_bytes(4) |> Base.url_encode64(padding: false) |> binary_part(0, 6)

    case Repo.get_by(Link, short_code: code) do
      nil -> code
      # Retry on collision
      _link -> generate_unique_short_code()
    end
  end
end
