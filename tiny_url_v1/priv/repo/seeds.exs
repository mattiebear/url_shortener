# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Or as part of ecto.reset:
#
#     mix ecto.reset
#
# Configuration (via environment variables):
#
#     SEED_COUNT=100000 mix run priv/repo/seeds.exs
#     SEED_COUNT=1000000 BATCH_SIZE=5000 mix ecto.reset
#
# Default: 1 million records with batch size of 10,000

defmodule TinyUrl.Seeds do
  alias TinyUrl.Repo

  @default_total_records 1_000_000
  @default_batch_size 10_000

  @sample_domains [
    "example.com",
    "google.com",
    "github.com",
    "stackoverflow.com",
    "reddit.com",
    "twitter.com",
    "linkedin.com",
    "medium.com",
    "youtube.com",
    "wikipedia.org",
    "amazon.com",
    "facebook.com",
    "instagram.com",
    "tiktok.com",
    "netflix.com"
  ]

  def run do
    total_records = get_env_int("SEED_COUNT", @default_total_records)
    batch_size = get_env_int("BATCH_SIZE", @default_batch_size)

    IO.puts("""

    ╔═══════════════════════════════════════════════════════════╗
    ║           TinyURL Database Seeder                         ║
    ╚═══════════════════════════════════════════════════════════╝

    Configuration:
      • Total records: #{format_number(total_records)}
      • Batch size: #{format_number(batch_size)}
      • Batches: #{div(total_records, batch_size)}

    """)

    confirm_and_seed(total_records, batch_size)
  end

  defp confirm_and_seed(total_records, batch_size) do
    existing_count = Repo.aggregate(TinyUrl.Links.Link, :count, :id)

    if existing_count > 0 do
      IO.puts("⚠️  Database currently contains #{format_number(existing_count)} records")
      IO.puts("⚠️  These will be DELETED before seeding!")
      IO.write("\nContinue? [y/N]: ")

      response = IO.gets("")

      case response do
        :eof ->
          # Non-interactive mode (e.g., piped input) - proceed automatically
          IO.puts("y (auto-confirmed in non-interactive mode)")
          execute_seed(total_records, batch_size)

        input when is_binary(input) ->
          case String.trim(input) |> String.downcase() do
            "y" -> execute_seed(total_records, batch_size)
            _ -> IO.puts("\n❌ Seeding cancelled")
          end
      end
    else
      execute_seed(total_records, batch_size)
    end
  end

  defp execute_seed(total_records, batch_size) do
    start_time = System.monotonic_time()

    # Step 1: Clear existing data
    clear_existing_data()

    # Step 2: Generate unique short codes
    short_codes = generate_unique_short_codes(total_records)

    # Step 3: Insert in batches with progress tracking
    insert_in_batches(short_codes, batch_size, total_records)

    # Step 4: Show summary
    show_summary(start_time, total_records)
  end

  defp clear_existing_data do
    IO.puts("🗑️  Clearing existing links...")
    {deleted_count, _} = Repo.delete_all(TinyUrl.Links.Link)
    IO.puts("   Deleted #{format_number(deleted_count)} existing records\n")
  end

  defp generate_unique_short_codes(count) do
    IO.puts("🔑 Pre-generating #{format_number(count)} unique short codes...")
    progress_start = System.monotonic_time()

    # Generate with progress tracking
    codes =
      Stream.repeatedly(fn -> generate_short_code() end)
      |> Stream.uniq()
      |> Stream.take(count)
      |> Enum.to_list()

    progress_duration = System.monotonic_time() - progress_start
    progress_seconds = System.convert_time_unit(progress_duration, :native, :millisecond) / 1000

    IO.puts(
      "   ✅ Generated #{format_number(length(codes))} codes in #{Float.round(progress_seconds, 2)}s\n"
    )

    codes
  end

  defp generate_short_code do
    :crypto.strong_rand_bytes(4)
    |> Base.url_encode64(padding: false)
    |> binary_part(0, 6)
  end

  defp insert_in_batches(short_codes, batch_size, total_records) do
    IO.puts("💾 Inserting records in batches of #{format_number(batch_size)}...")
    IO.puts("   Progress:")

    total_batches = div(total_records, batch_size)

    short_codes
    |> Enum.chunk_every(batch_size)
    |> Enum.with_index(1)
    |> Enum.each(fn {batch_codes, batch_num} ->
      insert_batch(batch_codes, batch_num, total_batches, total_records)
    end)

    IO.puts("")
  end

  defp insert_batch(short_codes, batch_num, total_batches, total_records) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    records =
      Enum.map(short_codes, fn short_code ->
        %{
          original_url: generate_url(),
          short_code: short_code,
          inserted_at: now,
          updated_at: now
        }
      end)

    # Use Repo.insert_all for bulk insert (bypasses changesets)
    {_count, _} = Repo.insert_all(TinyUrl.Links.Link, records)

    # Calculate progress
    total_inserted = min(batch_num * length(short_codes), total_records)
    progress = Float.round(total_inserted / total_records * 100, 1)
    bar = progress_bar(progress)

    IO.write(
      "\r   #{bar} #{progress}% | Batch #{batch_num}/#{total_batches} | #{format_number(total_inserted)}/#{format_number(total_records)} records"
    )
  end

  defp progress_bar(percentage) do
    # 40 chars = 100%
    filled = round(percentage / 2.5)
    empty = 40 - filled
    "#{String.duplicate("█", filled)}#{String.duplicate("░", empty)}"
  end

  defp generate_url do
    case :rand.uniform(6) do
      1 ->
        # Simple domain URLs
        domain = Enum.random(@sample_domains)
        "https://#{domain}"

      2 ->
        # URLs with single path
        domain = Enum.random(@sample_domains)

        path =
          Enum.random(["blog", "docs", "api", "products", "about", "contact", "help", "support"])

        "https://#{domain}/#{path}"

      3 ->
        # URLs with nested paths and IDs
        domain = Enum.random(@sample_domains)
        path1 = Enum.random(["post", "article", "user", "product", "video", "channel"])
        id = :rand.uniform(999_999)
        "https://#{domain}/#{path1}/#{id}"

      4 ->
        # URLs with query parameters
        domain = Enum.random(@sample_domains)
        param = Enum.random(["id", "q", "ref", "source", "utm_campaign", "utm_source"])
        value = :rand.uniform(99999)
        "https://#{domain}?#{param}=#{value}"

      5 ->
        # Complex URLs with multiple params
        domain = Enum.random(@sample_domains)
        path = Enum.random(["search", "results", "category", "filter"])

        query =
          "q=#{:rand.uniform(999)}&page=#{:rand.uniform(10)}&sort=#{Enum.random(["date", "popular", "relevant"])}"

        "https://#{domain}/#{path}?#{query}"

      6 ->
        # Very long URLs (for testing)
        domain = Enum.random(@sample_domains)

        path =
          Enum.join(
            Enum.map(1..:rand.uniform(5), fn _ -> Enum.random(["section", "category", "item"]) end),
            "/"
          )

        params =
          Enum.map_join(1..:rand.uniform(3), "&", fn i ->
            "param#{i}=value#{:rand.uniform(100)}"
          end)

        "https://#{domain}/#{path}?#{params}"
    end
  end

  defp show_summary(start_time, total_records) do
    duration = System.monotonic_time() - start_time
    duration_seconds = System.convert_time_unit(duration, :native, :millisecond) / 1000
    rate = Float.round(total_records / duration_seconds, 2)

    # Get database stats
    final_count = Repo.aggregate(TinyUrl.Links.Link, :count, :id)

    IO.puts("""


    ╔═══════════════════════════════════════════════════════════╗
    ║                     Seeding Complete!                     ║
    ╚═══════════════════════════════════════════════════════════╝

    Results:
      ✅ Records inserted: #{format_number(final_count)}
      ⏱️  Total time: #{format_duration(duration_seconds)}
      📊 Insert rate: #{format_number(rate)} records/second
      💾 Database size: ~#{estimate_db_size(final_count)}

    Next steps:
      • Start server: mix phx.server
      • Run tests: mix test
      • Check record count: mix run -e "IO.inspect(TinyUrl.Repo.aggregate(TinyUrl.Links.Link, :count, :id))"

    """)
  end

  defp get_env_int(key, default) do
    case System.get_env(key) do
      nil -> default
      value -> String.to_integer(value)
    end
  end

  defp format_number(num) when num >= 1_000_000 do
    "#{Float.round(num / 1_000_000, 1)}M"
  end

  defp format_number(num) when num >= 1_000 do
    "#{Float.round(num / 1_000, 1)}K"
  end

  defp format_number(num), do: to_string(num)

  defp format_duration(seconds) when seconds >= 60 do
    minutes = div(trunc(seconds), 60)
    remaining_seconds = rem(trunc(seconds), 60)
    "#{minutes}m #{remaining_seconds}s"
  end

  defp format_duration(seconds) do
    "#{Float.round(seconds, 2)}s"
  end

  defp estimate_db_size(record_count) do
    # Rough estimate: ~150 bytes per record (URL + short_code + timestamps + overhead)
    bytes = record_count * 150

    cond do
      bytes >= 1_073_741_824 -> "#{Float.round(bytes / 1_073_741_824, 2)} GB"
      bytes >= 1_048_576 -> "#{Float.round(bytes / 1_048_576, 2)} MB"
      bytes >= 1_024 -> "#{Float.round(bytes / 1_024, 2)} KB"
      true -> "#{bytes} bytes"
    end
  end
end

# Run the seeder
TinyUrl.Seeds.run()
