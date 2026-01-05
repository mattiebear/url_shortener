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
    start_time = System.monotonic_time()

    result =
      case Links.get_link_by_short_code(short_code) do
        nil ->
          render(conn, :not_found)

        link ->
          duration = System.monotonic_time() - start_time
          :telemetry.execute([:tiny_url, :links, :redirect], %{duration: duration, count: 1})
          redirect(conn, external: link.original_url)
      end

    result
  end

  def create(conn, %{"link" => link_params}) do
    start_time = System.monotonic_time()

    case Links.create_link(link_params) do
      {:ok, link} ->
        duration = System.monotonic_time() - start_time

        Logger.info("Created short URL",
          short_code: link.short_code,
          original_url: link.original_url
        )

        :telemetry.execute([:tiny_url, :links, :create], %{duration: duration}, %{source: :web})

        changeset = Links.change_link(%Link{})
        render(conn, :new, changeset: changeset, link: link)

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset, link: nil)
    end
  end
end
