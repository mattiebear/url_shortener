# TinyUrl

A simple and fun URL shortener built with Phoenix Framework. This is version 1 - an intentionally straightforward implementation focused on core functionality rather than optimization.

## Features

- **Simple URL Shortening**: Transform long URLs into short, shareable links
- **Clean, Modern UI**: Built with Tailwind CSS and daisyUI for a delightful user experience
- **Dark/Light Theme**: Automatic theme switching with system preference detection
- **No Tracking**: Privacy-friendly - no analytics or user tracking
- **Free & Open**: No signup required, no premium tiers

## Tech Stack

- **Phoenix Framework**: Modern web framework for Elixir
- **PostgreSQL**: Reliable database for URL storage
- **Tailwind CSS + daisyUI**: Utility-first CSS with beautiful components
- **Docker**: Containerized PostgreSQL, Prometheus, and Grafana
- **Prometheus**: Metrics collection and monitoring
- **Grafana**: Metrics visualization and dashboards
- **Telemetry**: Real-time application metrics and instrumentation

## Getting Started

### Prerequisites

- Elixir 1.14+ and Erlang/OTP 25+
- Docker and Docker Compose (for database)
- Node.js 18+ (for asset compilation)

### Installation

1. **Start the infrastructure** (PostgreSQL, Prometheus, Grafana):
   ```bash
   docker compose up -d
   ```

2. **Install dependencies**:
   ```bash
   mix deps.get
   mix setup
   ```
   This will install Elixir dependencies, create the database, run migrations, and install Node.js dependencies.

3. **Start the Phoenix server**:
   ```bash
   mix phx.server
   ```
   
   Or start it inside IEx for interactive debugging:
   ```bash
   iex -S mix phx.server
   ```

4. **Access the application and dashboards**:
   - **Application**: http://localhost:4000
   - **Grafana**: http://localhost:3000 (login: admin/admin)
   - **Prometheus**: http://localhost:9090
   - **Metrics endpoint**: http://localhost:9568/metrics

### Development Commands

- `mix test` - Run the test suite
- `mix format` - Format code
- `mix precommit` - Run pre-commit checks (format, tests, build)
- `docker compose down` - Stop all services (database, Prometheus, Grafana)
- `docker compose down -v` - Stop all services and remove data
- `./k6_docker.sh` - Run k6 load test (no local installation required)

## Project Structure

```
lib/
├── tiny_url/           # Core application logic
│   └── repo.ex         # Database repository
└── tiny_url_web/       # Web interface
    ├── controllers/    # HTTP request handlers
    ├── components/     # Reusable UI components
    └── router.ex       # Route definitions
```

## Metrics and Monitoring

This v1 implementation is instrumented with comprehensive metrics to help identify performance bottlenecks during load testing.

### Available Metrics

**Application Metrics:**
- `tiny_url.links.create.duration` - Time to create a shortened link
- `tiny_url.links.redirect.duration` - Time to lookup and redirect
- `tiny_url.links.create.count` - Total links created
- `tiny_url.links.redirect.count` - Total successful redirects
- `tiny_url.links.not_found.count` - Total 404 errors

**Phoenix Metrics:**
- `phoenix.router_dispatch.stop.duration` - Overall request latency (p50, p95, p99)
- `phoenix.endpoint.stop.duration` - Endpoint processing time

**Database Metrics:**
- `tiny_url.repo.query.total_time` - Total query execution time
- `tiny_url.repo.query.queue_time` - Time waiting for DB connection
- `tiny_url.repo.query.query_time` - Actual query execution time

**VM Metrics:**
- `vm.memory.total` - Memory usage
- `vm.total_run_queue_lengths.cpu` - CPU saturation indicator

### Setting Up Grafana

1. **Access Grafana** at http://localhost:3000 (admin/admin)

2. **Add Prometheus data source**:
   - Go to Configuration → Data Sources → Add data source
   - Select "Prometheus"
   - Set URL to: `http://prometheus:9090`
   - Click "Save & Test"

3. **Create a dashboard** with these example queries:
   ```promql
   # Requests per second
   rate(tiny_url_links_redirect_count[1m])
   
   # Average response time
   tiny_url_links_redirect_duration_milliseconds_sum / tiny_url_links_redirect_duration_milliseconds_count
   
   # P95 latency
   histogram_quantile(0.95, rate(phoenix_router_dispatch_stop_duration_milliseconds_bucket[5m]))
   
   # 404 rate
   rate(tiny_url_links_not_found_count[1m])
   ```

### Load Testing with k6

k6 is a modern load testing tool by Grafana Labs that provides powerful testing capabilities and detailed metrics.

**Run the load test (using Docker - no installation required):**
```bash
./k6_docker.sh
```

This script runs k6 in a Docker container, so you don't need to install k6 locally.

**The k6 test includes:**
- **Setup phase**: Creates 20 short URLs before the test
- **Load stages**:
  - Ramp up to 10 users (30s)
  - Ramp up to 50 users (1m)
  - Hold at 50 users (2m)
  - Spike to 100 users (30s)
  - Hold at 100 users (1m)
  - Ramp down to 0 (30s)
- **Test scenarios**:
  - 20% creates new links
  - 75% follows redirects
  - 5% tests 404s
- **Thresholds** (pass/fail criteria):
  - 95% of requests < 500ms
  - 99% of requests < 1000ms
  - Less than 1% failure rate

**Alternative: Install k6 locally**

If you prefer to install k6 directly:
```bash
# Arch Linux (AUR)
yay -S k6

# macOS
brew install k6

# Other systems: https://k6.io/docs/get-started/installation/
```

Then run directly:
```bash
k6 run load_test.js
```

**View k6 output:**
k6 provides real-time CLI output showing request rates, response times, and pass/fail status for thresholds.

#### Monitoring During Load Tests

Watch the Grafana dashboard in real-time to see:
- Request throughput (requests/second)
- Response time percentiles (p50, p95, p99)
- Database query performance
- Error rates
- System resource usage (memory, CPU)

## About This Version

This is version 1 (v1) of the URL shortener - a straightforward, unoptimized implementation designed to demonstrate core functionality. It prioritizes simplicity and clarity over performance optimization and scalability.

The comprehensive metrics and monitoring setup allows you to identify performance bottlenecks and understand system behavior under load, which will inform optimization decisions in future versions.

## Learn More About Phoenix

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
