defmodule TinyUrlWeb.LinkController do
  use TinyUrlWeb, :controller

  def new(conn, _params) do
    render(conn, "new.html")
  end

  def show(conn, _params) do
    redirect(conn, to: ~p"/")
  end

  def create(conn, _params) do
    redirect(conn, to: ~p"/")
  end
end
