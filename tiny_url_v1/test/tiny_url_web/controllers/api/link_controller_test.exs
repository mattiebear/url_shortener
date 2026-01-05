defmodule TinyUrlWeb.API.LinkControllerTest do
  use TinyUrlWeb.ConnCase, async: true

  alias TinyUrl.Links

  describe "POST /api/links (create)" do
    test "creates a link with valid URL and returns JSON", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/links", %{original_url: "https://example.com"})

      assert json = json_response(conn, 201)
      assert json["short_code"] != nil
      assert String.length(json["short_code"]) == 6
      assert json["original_url"] == "https://example.com"
      assert json["short_url"] =~ ~r|http://.*/.{6}|
    end

    test "returns 422 when URL is missing", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/links", %{})

      assert json = json_response(conn, 422)
      assert json["errors"]["original_url"] != nil
    end

    test "returns 422 when URL format is invalid", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/links", %{original_url: "not-a-url"})

      assert json = json_response(conn, 422)
      assert json["errors"]["original_url"] != nil
    end

    test "returns 422 when URL is too short", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/links", %{original_url: "http://x"})

      assert json = json_response(conn, 422)
      assert json["errors"]["original_url"] != nil
    end

    test "creates link with http URL", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/links", %{original_url: "http://example.com"})

      assert json = json_response(conn, 201)
      assert json["original_url"] == "http://example.com"
    end

    test "creates link with https URL", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/links", %{original_url: "https://example.com"})

      assert json = json_response(conn, 201)
      assert json["original_url"] == "https://example.com"
    end

    test "creates link with URL containing query params", %{conn: conn} do
      url = "https://example.com/page?foo=bar&baz=qux"

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/links", %{original_url: url})

      assert json = json_response(conn, 201)
      assert json["original_url"] == url
    end

    test "persists the link to the database", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/links", %{original_url: "https://example.com/api-test"})

      json = json_response(conn, 201)
      short_code = json["short_code"]

      link = Links.get_link_by_short_code(short_code)
      assert link != nil
      assert link.original_url == "https://example.com/api-test"
    end

    test "does not require CSRF token" do
      # This test verifies the API endpoint works without CSRF protection
      # by using a fresh conn without session
      conn =
        build_conn()
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/links", %{original_url: "https://example.com"})

      assert json = json_response(conn, 201)
      assert json["short_code"] != nil
    end

    test "created link can be used for redirects", %{conn: conn} do
      # Create via API
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> post(~p"/api/links", %{original_url: "https://example.com/redirect-test"})

      json = json_response(conn, 201)
      short_code = json["short_code"]

      # Use the short link
      conn = get(build_conn(), ~p"/#{short_code}")
      assert redirected_to(conn, 302) == "https://example.com/redirect-test"
    end
  end
end
