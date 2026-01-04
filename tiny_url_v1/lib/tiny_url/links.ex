defmodule TinyUrl.Links do
  alias TinyUrl.Links.Link

  def change_link(%Link{} = link, attrs \\ %{}) when is_map(attrs) do
    Link.changeset(link, attrs)
  end

  def generate_short_code do
    :crypto.strong_rand_bytes(8) |> Base.url_encode64() |> binary_part(0, 8)
  end
end
