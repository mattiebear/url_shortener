defmodule TinyUrlWeb.LinkController do
  require Logger

  use TinyUrlWeb, :controller

  alias TinyUrl.Links
  alias TinyUrl.Links.Link

  def new(conn, _params) do
    changeset = Links.change_link(%Link{})
    render(conn, :new, changeset: changeset, link: nil)
  end

  def show(conn, %{"short_code" => short_code}) do
    Logger.metadata(short_code: short_code)
    Logger.info("Redirect request")

    case Links.get_link_by_short_code(short_code) do
      nil ->
        Logger.warning("Link not found")
        render(conn, :not_found)

      link ->
        Logger.metadata(original_url: link.original_url)
        Logger.info("Redirecting to original URL")
        redirect(conn, external: link.original_url)
    end
  end

  def create(conn, %{"link" => link_params}) do
    original_url = Map.get(link_params, "original_url", "")
    Logger.metadata(original_url: String.slice(original_url, 0, 200))
    Logger.info("Link creation request")

    case Links.create_link(link_params) do
      {:ok, link} ->
        Logger.metadata(short_code: link.short_code)
        Logger.info("Link created successfully")
        changeset = Links.change_link(%Link{})
        render(conn, :new, changeset: changeset, link: link)

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
        Logger.metadata(validation_errors: errors)
        Logger.warning("Link creation failed")
        render(conn, :new, changeset: changeset, link: nil)
    end
  end
end
