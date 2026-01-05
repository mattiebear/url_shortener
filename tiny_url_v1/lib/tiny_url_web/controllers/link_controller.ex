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

    start_time = System.monotonic_time()

    result =
      case Links.get_link_by_short_code(short_code) do
        nil ->
          Logger.warning("Link not found")
          :telemetry.execute([:tiny_url, :links, :not_found], %{count: 1})
          render(conn, :not_found)

        link ->
          Logger.metadata(original_url: link.original_url)
          Logger.info("Redirecting to original URL")

          duration = System.monotonic_time() - start_time
          :telemetry.execute([:tiny_url, :links, :redirect], %{duration: duration, count: 1})

          redirect(conn, external: link.original_url)
      end

    result
  end

  def create(conn, %{"link" => link_params}) do
    original_url = Map.get(link_params, "original_url", "")
    Logger.metadata(original_url: String.slice(original_url, 0, 200))
    Logger.info("Link creation request")

    start_time = System.monotonic_time()

    case Links.create_link(link_params) do
      {:ok, link} ->
        duration = System.monotonic_time() - start_time
        :telemetry.execute([:tiny_url, :links, :create], %{duration: duration, count: 1})

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

  def create_api(conn, %{"original_url" => original_url}) do
    Logger.metadata(original_url: String.slice(original_url, 0, 200))
    Logger.info("API link creation request")

    start_time = System.monotonic_time()

    case Links.create_link(%{"original_url" => original_url}) do
      {:ok, link} ->
        duration = System.monotonic_time() - start_time
        :telemetry.execute([:tiny_url, :links, :create], %{duration: duration, count: 1})

        Logger.metadata(short_code: link.short_code)
        Logger.info("Link created successfully via API")

        conn
        |> put_status(:created)
        |> render(:create, link: link)

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
        Logger.metadata(validation_errors: errors)
        Logger.warning("API link creation failed")

        conn
        |> put_status(:unprocessable_entity)
        |> render(:error, changeset: changeset)
    end
  end

  def create_api(conn, _params) do
    Logger.warning("API link creation request missing original_url")

    changeset =
      %Link{}
      |> Ecto.Changeset.change()
      |> Ecto.Changeset.add_error(:original_url, "can't be blank")

    conn
    |> put_status(:unprocessable_entity)
    |> render(:error, changeset: changeset)
  end
end
