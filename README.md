# URL Shortener - System Design Evolution

## Project Purpose

This project demonstrates the evolution of a URL shortener service from a naive implementation to a production-ready, scalable system. The goal is to showcase common mistakes made by inexperienced developers and how proper system design principles can address performance, scalability, and reliability concerns.

## Project Structure

The project is organized into multiple versions:

- **tiny_url_v1**: A naive implementation built by an inexperienced developer, showcasing common pitfalls
- **tiny_url_v2** (planned): An improved version incorporating better system design practices

## Load Testing Overview

Each version of the system undergoes comprehensive load testing using k6 to measure performance characteristics under different traffic patterns. The tests help identify bottlenecks and validate architectural decisions.

### Test Scenarios

1. **Baseline Load Test** - Establishes performance baselines under light load (5-20 concurrent users)
2. **Heavy Load Test** - Tests system behavior under sustained high traffic and stress conditions

### Monitoring Stack

The project includes a complete observability setup:

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization dashboards for real-time monitoring
- **k6**: Load testing tool with custom metrics

## Documentation

Detailed performance analysis and load test results are available in the `docs/` directory:

- [NAIVE_V1.md](docs/NAIVE_V1.md) - Performance analysis of the naive implementation

## Getting Started

See the individual version directories for setup and deployment instructions.
