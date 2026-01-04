defmodule TinyUrl.Repo do
  use Ecto.Repo,
    otp_app: :tiny_url,
    adapter: Ecto.Adapters.Postgres
end
