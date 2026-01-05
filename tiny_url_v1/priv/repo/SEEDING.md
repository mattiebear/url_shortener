# Database Seeding Guide

## Quick Start

The seed file is configured to generate **1 million records** by default and runs automatically with `mix ecto.reset`.

```bash
# Standard seeding (1M records)
mix run priv/repo/seeds.exs

# Or use ecto.reset (drops, creates, migrates, and seeds)
mix ecto.reset
```

---

## Configuration

Customize seeding behavior using environment variables:

### Record Count

```bash
# Generate 10,000 records (for quick testing)
SEED_COUNT=10000 mix run priv/repo/seeds.exs

# Generate 100,000 records
SEED_COUNT=100000 mix run priv/repo/seeds.exs

# Generate 5 million records
SEED_COUNT=5000000 mix run priv/repo/seeds.exs
```

### Batch Size

```bash
# Smaller batches (less memory, slower)
SEED_COUNT=1000000 BATCH_SIZE=5000 mix run priv/repo/seeds.exs

# Larger batches (more memory, faster)
SEED_COUNT=1000000 BATCH_SIZE=20000 mix run priv/repo/seeds.exs
```

### Combined with ecto.reset

```bash
# Custom seeding with database reset
SEED_COUNT=500000 BATCH_SIZE=10000 mix ecto.reset
```

---

## Features

- **Pre-generated unique short codes** - No collisions during insert
- **Bulk inserts with `Repo.insert_all/3`** - Maximum performance
- **Batch processing** - Memory-efficient handling of large datasets
- **Progress bar** - Real-time visual feedback
- **Confirmation prompt** - Prevents accidental data loss
- **Performance metrics** - Shows insert rate and database size estimation
- **Realistic test data** - Varied URL patterns for comprehensive testing

---

## Performance Tuning

### Batch Size Guidelines

| Total Records | Recommended Batch Size | Memory Usage | Expected Time |
|--------------|------------------------|--------------|---------------|
| 10K - 100K   | 1,000 - 5,000         | Low          | < 10s         |
| 100K - 1M    | 5,000 - 10,000        | Medium       | 30-60s        |
| 1M - 5M      | 10,000 - 20,000       | High         | 2-5min        |
| 5M+          | 20,000 - 50,000       | Very High    | 5-15min       |

### Optimization Tips

**1. Increase batch size for faster inserts** (uses more memory)
```bash
BATCH_SIZE=20000 mix run priv/repo/seeds.exs
```

**2. Decrease batch size if you encounter memory issues**
```bash
BATCH_SIZE=5000 mix run priv/repo/seeds.exs
```

**3. Disable SQL logging** for better performance
```elixir
# In config/dev.exs
config :tiny_url, TinyUrl.Repo,
  log: false  # Disable SQL logging during seeding
```

**4. PostgreSQL tuning** (for very large datasets)
```sql
-- Temporarily increase work_mem for the session
SET work_mem = '256MB';
```

---

## Understanding Performance

### Why `Repo.insert_all/3` is Fast

| Approach | Speed | Why |
|----------|-------|-----|
| `Repo.insert/2` (one by one) | Slow ❌ | Individual INSERTs, changeset validation, callbacks |
| `Repo.insert_all/3` (batched) | Fast ✅ | Single bulk INSERT, no changesets, no callbacks |

**Example Performance:**
```elixir
# SLOW - 1M records in ~30 minutes
Enum.each(records, fn record ->
  Repo.insert!(record)  # Individual INSERT statements
end)

# FAST - 1M records in ~30-60 seconds
Repo.insert_all(Link, records)  # Single bulk INSERT per batch
```

### Data Generation Strategy

The seed file pre-generates all short codes to ensure uniqueness without database lookups:

```elixir
# ✅ Good: Pre-generate all codes (no database lookups during insert)
short_codes = generate_unique_short_codes(1_000_000)
# Then insert with pre-generated codes

# ❌ Bad: Generate during insert (causes N database lookups)
Enum.each(records, fn _ ->
  code = generate_code_and_check_db()  # Slow!
end)
```

---

## Output Example

```
╔═══════════════════════════════════════════════════════════╗
║           TinyURL Database Seeder                         ║
╚═══════════════════════════════════════════════════════════╝

Configuration:
  • Total records: 1.0M
  • Batch size: 10.0K
  • Batches: 100

🗑️  Clearing existing links...
   Deleted 0 existing records

🔑 Pre-generating 1.0M unique short codes...
   ✅ Generated 1.0M codes in 3.45s

💾 Inserting records in batches of 10.0K...
   Progress:
   ████████████████████████████████████████ 100.0% | Batch 100/100 | 1.0M/1.0M records

╔═══════════════════════════════════════════════════════════╗
║                     Seeding Complete!                     ║
╚═══════════════════════════════════════════════════════════╝

Results:
  ✅ Records inserted: 1.0M
  ⏱️  Total time: 45.32s
  📊 Insert rate: 22,063.49 records/second
  💾 Database size: ~143.05 MB

Next steps:
  • Start server: mix phx.server
  • Run tests: mix test
  • Check record count: mix run -e "IO.inspect(TinyUrl.Repo.aggregate(TinyUrl.Links.Link, :count, :id))"
```

---

## Troubleshooting

### Out of Memory Errors

**Error:** `** (SystemLimitError) a system limit has been reached`

**Solution:** Reduce batch size
```bash
BATCH_SIZE=5000 mix run priv/repo/seeds.exs
```

### Slow Performance

**Issue:** Seeding takes longer than expected

**Solutions:**
1. Increase batch size (if you have RAM)
   ```bash
   BATCH_SIZE=20000 mix run priv/repo/seeds.exs
   ```

2. Disable database logging
   ```elixir
   # In config/dev.exs
   config :tiny_url, TinyUrl.Repo, log: false
   ```

3. Check disk I/O (use SSD if possible)

### Unique Constraint Violations

**Error:** `** (Ecto.ConstraintError) constraint error when attempting to insert struct`

**Cause:** Short code collision (very rare with 1M records)

**Solution:** The seed file handles this by pre-generating unique codes. If it still happens, it's a bug in the generation logic.

---

## Verifying Seeded Data

### Check Record Count
```bash
mix run -e "IO.inspect(TinyUrl.Repo.aggregate(TinyUrl.Links.Link, :count, :id))"
```

### Sample Random Records
```bash
mix run -e "
  import Ecto.Query
  TinyUrl.Repo.all(from l in TinyUrl.Links.Link, limit: 5, order_by: fragment(\"RANDOM()\"))
  |> IO.inspect()
"
```

### View First 5 Records
```bash
mix run -e "
  import Ecto.Query
  TinyUrl.Repo.all(from l in TinyUrl.Links.Link, limit: 5)
  |> Enum.each(fn link ->
    IO.puts(\"Short: \#{link.short_code} -> \#{link.original_url}\")
  end)
"
```

---

## Use Cases

### Load Testing
Seed large datasets for API load testing:
```bash
# Seed 1M records
mix run priv/repo/seeds.exs

# Then run load tests with tools like:
# - Apache Bench (ab)
# - wrk
# - k6
# - Locust
```

### Performance Benchmarking
Test query performance with realistic data volumes:
```elixir
Benchee.run(%{
  "get by short_code" => fn ->
    TinyUrl.Links.get_link_by_short_code("abc123")
  end
})
```

### Index Testing
Verify that database indexes work efficiently:
```sql
EXPLAIN ANALYZE SELECT * FROM links WHERE short_code = 'abc123';
```

---

## Cleanup

### Clear All Seeded Data
```bash
mix run -e "TinyUrl.Repo.delete_all(TinyUrl.Links.Link)"
```

### Reset Database Completely
```bash
mix ecto.reset
```

This will drop, create, migrate, and re-seed the database.
