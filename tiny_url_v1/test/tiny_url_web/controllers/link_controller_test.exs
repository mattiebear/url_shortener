defmodule TinyUrlWeb.LinkControllerTest do
  use TinyUrlWeb.ConnCase, async: true

  alias TinyUrl.Links

  describe "GET /new" do
    test "renders the new link form", %{conn: conn} do
      conn = get(conn, ~p"/")

      assert html_response(conn, 200)
      assert html = html_response(conn, 200)
      assert html =~ "Make Your Links"
      assert html =~ "Tiny"
      assert html =~ "Shrink It!"
    end

    test "assigns an empty changeset", %{conn: conn} do
      conn = get(conn, ~p"/")

      assert conn.assigns.changeset.data == %TinyUrl.Links.Link{}
      assert conn.assigns.changeset.changes == %{}
      refute conn.assigns.changeset.valid?
    end

    test "assigns link as nil", %{conn: conn} do
      conn = get(conn, ~p"/")

      assert conn.assigns.link == nil
    end
  end

  describe "POST /shorten (create)" do
    test "creates a link with valid URL", %{conn: conn} do
      conn = post(conn, ~p"/shorten", link: %{original_url: "https://example.com"})

      assert html = html_response(conn, 200)
      assert html =~ "Your link is ready!"
      assert html =~ "https://example.com"
    end

    test "assigns the created link", %{conn: conn} do
      conn = post(conn, ~p"/shorten", link: %{original_url: "https://example.com/long-url"})

      assert conn.assigns.link != nil
      assert conn.assigns.link.original_url == "https://example.com/long-url"
      assert conn.assigns.link.short_code != nil
      assert String.length(conn.assigns.link.short_code) == 6
    end

    test "displays the shortened URL", %{conn: conn} do
      conn = post(conn, ~p"/shorten", link: %{original_url: "https://example.com"})

      short_code = conn.assigns.link.short_code
      assert html = html_response(conn, 200)
      assert html =~ short_code
    end

    test "renders errors when URL is missing", %{conn: conn} do
      conn = post(conn, ~p"/shorten", link: %{original_url: ""})

      assert html = html_response(conn, 200)
      assert html =~ "can&#39;t be blank"
      assert conn.assigns.link == nil
    end

    test "renders errors when URL format is invalid", %{conn: conn} do
      conn = post(conn, ~p"/shorten", link: %{original_url: "not-a-url"})

      assert html = html_response(conn, 200)
      assert html =~ "must be a valid URL"
      assert conn.assigns.link == nil
    end

    test "renders errors when URL is too short", %{conn: conn} do
      conn = post(conn, ~p"/shorten", link: %{original_url: "http://x"})

      assert html = html_response(conn, 200)
      assert html =~ "should be at least 10 character"
      assert conn.assigns.link == nil
    end

    test "creates link with http URL", %{conn: conn} do
      conn = post(conn, ~p"/shorten", link: %{original_url: "http://example.com"})

      assert conn.assigns.link != nil
      assert conn.assigns.link.original_url == "http://example.com"
    end

    test "creates link with https URL", %{conn: conn} do
      conn = post(conn, ~p"/shorten", link: %{original_url: "https://example.com"})

      assert conn.assigns.link != nil
      assert conn.assigns.link.original_url == "https://example.com"
    end

    test "creates link with URL containing query params", %{conn: conn} do
      url = "https://example.com/page?foo=bar&baz=qux"
      conn = post(conn, ~p"/shorten", link: %{original_url: url})

      assert conn.assigns.link != nil
      assert conn.assigns.link.original_url == url
    end

    test "creates link with URL containing fragment", %{conn: conn} do
      url = "https://example.com/page#section"
      conn = post(conn, ~p"/shorten", link: %{original_url: url})

      assert conn.assigns.link != nil
      assert conn.assigns.link.original_url == url
    end

    test "creates link with long URL", %{conn: conn} do
      long_url = "https://example.com/" <> String.duplicate("a", 500)
      conn = post(conn, ~p"/shorten", link: %{original_url: long_url})

      assert conn.assigns.link != nil
      assert conn.assigns.link.original_url == long_url
    end

    test "persists the link to the database", %{conn: conn} do
      conn = post(conn, ~p"/shorten", link: %{original_url: "https://example.com"})

      short_code = conn.assigns.link.short_code
      link = Links.get_link_by_short_code(short_code)

      assert link != nil
      assert link.original_url == "https://example.com"
    end
  end

  describe "GET /:short_code (show)" do
    test "redirects to original URL when link exists", %{conn: conn} do
      {:ok, link} = Links.create_link(%{original_url: "https://example.com/test"})

      conn = get(conn, ~p"/#{link.short_code}")

      assert redirected_to(conn, 302) == "https://example.com/test"
    end

    test "redirects to URL with query params", %{conn: conn} do
      url = "https://example.com/page?foo=bar&baz=qux"
      {:ok, link} = Links.create_link(%{original_url: url})

      conn = get(conn, ~p"/#{link.short_code}")

      assert redirected_to(conn, 302) == url
    end

    test "redirects to URL with fragment", %{conn: conn} do
      url = "https://example.com/page#section"
      {:ok, link} = Links.create_link(%{original_url: url})

      conn = get(conn, ~p"/#{link.short_code}")

      assert redirected_to(conn, 302) == url
    end

    test "renders not_found when short_code does not exist", %{conn: conn} do
      conn = get(conn, ~p"/nonexistent")

      assert html = html_response(conn, 200)
      assert html =~ "Link Not Found"
      assert html =~ "short link"
    end

    test "renders not_found for invalid short_code format", %{conn: conn} do
      conn = get(conn, ~p"/invalid-code-format-123")

      assert html = html_response(conn, 200)
      assert html =~ "Link Not Found"
    end

    test "handles multiple redirects for the same link", %{conn: conn} do
      {:ok, link} = Links.create_link(%{original_url: "https://example.com"})

      # First redirect
      conn1 = get(conn, ~p"/#{link.short_code}")
      assert redirected_to(conn1, 302) == "https://example.com"

      # Second redirect (same link should still work)
      conn2 = get(conn, ~p"/#{link.short_code}")
      assert redirected_to(conn2, 302) == "https://example.com"
    end

    test "handles different links independently", %{conn: conn} do
      {:ok, link1} = Links.create_link(%{original_url: "https://example1.com"})
      {:ok, link2} = Links.create_link(%{original_url: "https://example2.com"})

      conn1 = get(conn, ~p"/#{link1.short_code}")
      assert redirected_to(conn1, 302) == "https://example1.com"

      conn2 = get(conn, ~p"/#{link2.short_code}")
      assert redirected_to(conn2, 302) == "https://example2.com"
    end
  end

  describe "integration: create and redirect" do
    test "creates a link and then successfully redirects", %{conn: conn} do
      # Create the link
      conn = post(conn, ~p"/shorten", link: %{original_url: "https://github.com"})
      short_code = conn.assigns.link.short_code

      # Use the short link
      conn = get(build_conn(), ~p"/#{short_code}")
      assert redirected_to(conn, 302) == "https://github.com"
    end

    test "multiple links can be created and all redirect correctly", %{conn: conn} do
      # Create first link
      conn1 = post(conn, ~p"/shorten", link: %{original_url: "https://elixir-lang.org"})
      short_code1 = conn1.assigns.link.short_code

      # Create second link
      conn2 =
        post(build_conn(), ~p"/shorten", link: %{original_url: "https://phoenixframework.org"})

      short_code2 = conn2.assigns.link.short_code

      # Verify both redirects work
      conn_redirect1 = get(build_conn(), ~p"/#{short_code1}")
      assert redirected_to(conn_redirect1, 302) == "https://elixir-lang.org"

      conn_redirect2 = get(build_conn(), ~p"/#{short_code2}")
      assert redirected_to(conn_redirect2, 302) == "https://phoenixframework.org"
    end
  end
end
