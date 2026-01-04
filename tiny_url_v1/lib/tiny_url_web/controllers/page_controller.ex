defmodule TinyUrlWeb.PageController do
  use TinyUrlWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
