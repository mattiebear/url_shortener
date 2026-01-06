# URL Shortener - System Design Evolution

## Project Purpose

This project demonstrates the evolution of a URL shortener service from a straightforward initial implementation to a production-ready, scalable system. The goal is to explore how different architectural decisions impact performance, scalability, and reliability through iterative improvements informed by load testing and observability.

## Project Structure

The project is organized into multiple versions:

- **tiny_url_v1**: A straightforward initial implementation focusing on core functionality
- **tiny_url_v2** (planned): An improved version incorporating lessons learned from v1's performance testing

## Load Testing Overview

Each version of the system undergoes comprehensive load testing using k6 to measure performance characteristics under different traffic patterns. The tests help identify bottlenecks and validate architectural decisions.

### Test Scenarios

1. **Baseline Load Test** - Establishes performance baselines under light load (5-20 concurrent users)
2. **Heavy Load Test** - Tests system behavior under sustained high traffic and stress conditions

### Performance Benchmarks

For a simple URL shortener service, here are general performance targets (P95 latency):

**Request Latency (End-to-End)**
- **Excellent**: < 50ms - Sub-50ms responses feel instant to users
- **Good**: 50-100ms - Still very responsive, acceptable for most use cases
- **Acceptable**: 100-200ms - Noticeable but tolerable delay
- **Slow**: 200-500ms - Users will perceive lag, needs improvement
- **Very Slow**: > 500ms - Poor user experience, requires optimization

**Database Query Latency**
- **Excellent**: < 5ms - Well-optimized queries with proper indexing
- **Good**: 5-10ms - Reasonable query performance
- **Acceptable**: 10-25ms - May indicate missing indexes or inefficient queries
- **Slow**: 25-50ms - Likely needs query optimization or better indexing
- **Very Slow**: > 50ms - Significant bottleneck, requires immediate attention

**Context**: These benchmarks assume:
- Single datacenter deployment (no cross-region latency)
- Simple read/write operations (lookups and inserts)
- Properly indexed database tables
- Modern hardware (SSD storage, sufficient RAM)

### Monitoring Stack

The project includes a complete observability setup:

- **Prometheus**: Metrics collection and storage
- **Grafana**: Visualization dashboards for real-time monitoring
- **k6**: Load testing tool with custom metrics

## Basic Performance Optimizations Applied

Even the "naive" v1 implementation includes some fundamental optimizations necessary for meaningful load testing:

### Configuration Improvements
- **Production Release Build**: Compiled BEAM bytecode with optimizations enabled (no Mix overhead)
- **Code Reloader Disabled**: Removes GenServer bottleneck that crashes under high load (~700 req/s)
- **Database Connection Pool**: Increased from default 10 to 100 connections for production builds
- **Connection Queue Tuning**: Extended queue timeouts (5000ms target/interval) to handle traffic bursts
- **SSL Disabled for Local Testing**: Removes encryption overhead during local load testing

### Why These Matter
- **Dev mode at ~700 req/s**: Code reloader GenServer crashes, server stops accepting connections
- **Pool size of 10 at ~1,200 users**: Database connection exhaustion causes cascading failures
- **Production build**: ~30-40% performance improvement from optimized compilation alone

These changes represent the minimum viable configuration for load testing. More sophisticated optimizations (caching, read replicas, CDN, horizontal scaling) are planned for v2.

## Documentation

Detailed performance analysis and load test results are available in the `docs/` directory:

- [NAIVE_V1.md](docs/NAIVE_V1.md) - Performance analysis of the naive implementation

## Getting Started

See the individual version directories for setup and deployment instructions.
