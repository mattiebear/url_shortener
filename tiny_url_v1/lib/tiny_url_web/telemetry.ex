defmodule TinyUrlWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000},
      # Add reporters as children of your supervision tree.
      # TelemetryMetricsPrometheus (not Core) includes HTTP server
      {TelemetryMetricsPrometheus, metrics: metrics(), port: 9568}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # URL Shortener Specific Metrics
      # Using last_value for duration tracking (Prometheus will show latest value)
      last_value("tiny_url.links.create.duration",
        unit: {:native, :millisecond},
        description: "Time to create a shortened link"
      ),
      last_value("tiny_url.links.redirect.duration",
        unit: {:native, :millisecond},
        description: "Time to lookup and redirect a link"
      ),
      # Using sum for counters (Prometheus will accumulate values)
      sum("tiny_url.links.create.count",
        description: "Total number of links created"
      ),
      sum("tiny_url.links.redirect.count",
        description: "Total number of successful redirects"
      ),
      sum("tiny_url.links.not_found.count",
        description: "Total number of 404s for invalid short codes"
      ),

      # Phoenix Metrics
      last_value("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      last_value("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      last_value("phoenix.router_dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      last_value("phoenix.router_dispatch.exception.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      last_value("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      last_value("phoenix.socket_connected.duration",
        unit: {:native, :millisecond}
      ),
      sum("phoenix.socket_drain.count"),
      last_value("phoenix.channel_joined.duration",
        unit: {:native, :millisecond}
      ),
      last_value("phoenix.channel_handled_in.duration",
        tags: [:event],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      last_value("tiny_url.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      last_value("tiny_url.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      last_value("tiny_url.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      last_value("tiny_url.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      last_value("tiny_url.repo.query.idle_time",
        unit: {:native, :millisecond},
        description:
          "The time the connection spent waiting before being checked out for the query"
      ),

      # VM Metrics
      last_value("vm.memory.total", unit: {:byte, :kilobyte}),
      last_value("vm.total_run_queue_lengths.total"),
      last_value("vm.total_run_queue_lengths.cpu"),
      last_value("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {TinyUrlWeb, :count_users, []}
    ]
  end
end
