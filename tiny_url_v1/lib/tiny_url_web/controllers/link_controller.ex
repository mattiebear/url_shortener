defmodule TinyUrlWeb.LinkController do
  use TinyUrlWeb, :controller

  alias TinyUrl.Links
  alias TinyUrl.Links.Link

  def new(conn, _params) do
    changeset = Links.change_link(%Link{})
    render(conn, "new.html", changeset: changeset)
  end

  def show(conn, _params) do
    redirect(conn, to: ~p"/")
  end

  def create(conn, _params) do
    redirect(conn, to: ~p"/")
  end
end
