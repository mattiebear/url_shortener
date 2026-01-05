defmodule TinyUrlWeb.LinkJSON do
  @doc """
  Renders a created link as JSON.
  """
  def create(%{link: link}) do
    %{
      short_code: link.short_code,
      original_url: link.original_url,
      short_url: url(link)
    }
  end

  @doc """
  Renders validation errors as JSON.
  """
  def error(%{changeset: changeset}) do
    %{
      errors: translate_errors(changeset)
    }
  end

  defp url(link) do
    # For now, we'll construct a simple URL
    # In production, you might want to use TinyUrlWeb.Endpoint.url()
    "http://localhost:4000/#{link.short_code}"
  end

  defp translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
