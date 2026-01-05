defmodule TinyUrlWeb.API.LinkController do
  require Logger

  use TinyUrlWeb, :controller

  alias TinyUrl.Links

  def create(conn, params) do
    start_time = System.monotonic_time()

    case Links.create_link(params) do
      {:ok, link} ->
        duration = System.monotonic_time() - start_time

        Logger.info("Created short URL via API",
          short_code: link.short_code,
          original_url: link.original_url
        )

        :telemetry.execute([:tiny_url, :links, :create], %{duration: duration}, %{source: :api})

        conn
        |> put_status(:created)
        |> render(:create, link: link)

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)
    end
  end
end
