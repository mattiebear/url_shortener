defmodule TinyUrlWeb.LinkController do
  use TinyUrlWeb, :controller

  alias TinyUrl.Links
  alias TinyUrl.Links.Link

  def new(conn, _params) do
    changeset = Links.change_link(%Link{})
    render(conn, :new, changeset: changeset, link: nil)
  end

  def show(conn, %{"short_code" => short_code}) do
    case Links.get_link_by_short_code(short_code) do
      nil ->
        render(conn, :not_found)

      link ->
        redirect(conn, external: link.original_url)
    end
  end

  def create(conn, %{"link" => link_params}) do
    case Links.create_link(link_params) do
      {:ok, link} ->
        changeset = Links.change_link(%Link{})
        render(conn, :new, changeset: changeset, link: link)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, link: nil)
    end
  end
end
