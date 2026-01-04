defmodule TinyUrl.LinksTest do
  use TinyUrl.DataCase, async: true

  alias TinyUrl.Links
  alias TinyUrl.Links.Link

  describe "change_link/2" do
    test "returns a changeset for a new link" do
      changeset = Links.change_link(%Link{})
      assert %Ecto.Changeset{} = changeset
      assert changeset.data == %Link{}
    end

    test "returns a changeset with given attributes" do
      attrs = %{original_url: "https://example.com"}
      changeset = Links.change_link(%Link{}, attrs)

      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.original_url == "https://example.com"
    end

    test "returns a changeset for an existing link" do
      link = %Link{original_url: "https://example.com", short_code: "abc123"}
      changeset = Links.change_link(link)

      assert %Ecto.Changeset{} = changeset
      assert changeset.data == link
    end

    test "returns a changeset when updating an existing link" do
      link = %Link{original_url: "https://example.com", short_code: "abc123"}
      attrs = %{original_url: "https://new-url.com"}
      changeset = Links.change_link(link, attrs)

      assert %Ecto.Changeset{} = changeset
      assert changeset.changes.original_url == "https://new-url.com"
    end
  end

  describe "create_link/1" do
    test "creates a link with valid attributes" do
      attrs = %{original_url: "https://example.com"}

      assert {:ok, %Link{} = link} = Links.create_link(attrs)
      assert link.original_url == "https://example.com"
      assert link.short_code != nil
      assert String.length(link.short_code) == 6
    end

    test "generates a unique short_code automatically" do
      attrs = %{original_url: "https://example.com"}

      assert {:ok, link1} = Links.create_link(attrs)
      assert {:ok, link2} = Links.create_link(attrs)

      assert link1.short_code != link2.short_code
    end

    test "short_code is URL-safe base64 encoded" do
      attrs = %{original_url: "https://example.com"}

      assert {:ok, link} = Links.create_link(attrs)

      # URL-safe base64 should only contain alphanumeric, hyphen, and underscore
      assert link.short_code =~ ~r/^[A-Za-z0-9_-]+$/
    end

    test "returns error changeset when original_url is missing" do
      attrs = %{}

      assert {:error, %Ecto.Changeset{} = changeset} = Links.create_link(attrs)
      assert %{original_url: ["can't be blank"]} = errors_on(changeset)
    end

    test "returns error changeset when original_url is nil" do
      attrs = %{original_url: nil}

      assert {:error, %Ecto.Changeset{} = changeset} = Links.create_link(attrs)
      assert %{original_url: ["can't be blank"]} = errors_on(changeset)
    end

    test "creates link with very long URL" do
      long_url = "https://example.com/" <> String.duplicate("a", 2000)
      attrs = %{original_url: long_url}

      assert {:ok, %Link{} = link} = Links.create_link(attrs)
      assert link.original_url == long_url
    end

    test "creates multiple links with different URLs" do
      attrs1 = %{original_url: "https://example.com/page1"}
      attrs2 = %{original_url: "https://example.com/page2"}
      attrs3 = %{original_url: "https://different-domain.org"}

      assert {:ok, link1} = Links.create_link(attrs1)
      assert {:ok, link2} = Links.create_link(attrs2)
      assert {:ok, link3} = Links.create_link(attrs3)

      # All should have different short codes
      short_codes = [link1.short_code, link2.short_code, link3.short_code]
      assert length(Enum.uniq(short_codes)) == 3
    end

    test "allows creating multiple links with the same original_url" do
      attrs = %{original_url: "https://example.com"}

      assert {:ok, link1} = Links.create_link(attrs)
      assert {:ok, link2} = Links.create_link(attrs)

      # Same URL should get different short codes
      assert link1.original_url == link2.original_url
      assert link1.short_code != link2.short_code
    end

    test "sets timestamps on creation" do
      attrs = %{original_url: "https://example.com"}

      assert {:ok, link} = Links.create_link(attrs)
      assert %DateTime{} = link.inserted_at
      assert %DateTime{} = link.updated_at
    end

    test "does not set short_code when changeset is invalid" do
      attrs = %{original_url: nil}

      assert {:error, changeset} = Links.create_link(attrs)

      # short_code should not be in changes since changeset was invalid
      refute Map.has_key?(changeset.changes, :short_code)
    end
  end

  describe "short_code uniqueness" do
    test "handles collision by regenerating code" do
      # This test verifies the collision handling logic exists
      # In practice, with 6-character base64 codes, collisions are very rare
      # but the code should handle them gracefully

      attrs = %{original_url: "https://example.com"}

      # Create many links to increase chance of collision handling being tested
      # (though actual collisions are unlikely with 6-char codes)
      links =
        for _i <- 1..20 do
          {:ok, link} = Links.create_link(attrs)
          link
        end

      short_codes = Enum.map(links, & &1.short_code)

      # All codes should be unique
      assert length(Enum.uniq(short_codes)) == 20
    end

    test "verifies no duplicate short_codes in database" do
      attrs = %{original_url: "https://example.com"}

      # Create multiple links
      for _i <- 1..10 do
        {:ok, _link} = Links.create_link(attrs)
      end

      # Query all short codes
      short_codes =
        Repo.all(Link)
        |> Enum.map(& &1.short_code)

      # Verify all are unique
      assert length(short_codes) == length(Enum.uniq(short_codes))
    end
  end
end
