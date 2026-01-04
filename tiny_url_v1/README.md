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
- **Docker**: Containerized PostgreSQL for easy local development

## Getting Started

### Prerequisites

- Elixir 1.14+ and Erlang/OTP 25+
- Docker and Docker Compose (for database)
- Node.js 18+ (for asset compilation)

### Installation

1. **Start the database**:
   ```bash
   docker compose up -d
   ```

2. **Install dependencies**:
   ```bash
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

4. **Visit the application**:
   Open [`localhost:4000`](http://localhost:4000) in your browser.

### Development Commands

- `mix test` - Run the test suite
- `mix format` - Format code
- `mix precommit` - Run pre-commit checks (format, tests, build)
- `docker compose down` - Stop the database
- `docker compose down -v` - Stop the database and remove data

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

## About This Version

This is version 1 (v1) of the URL shortener - a straightforward, unoptimized implementation designed to demonstrate core functionality. It prioritizes simplicity and clarity over performance optimization and scalability.

## Learn More About Phoenix

- Official website: https://www.phoenixframework.org/
- Guides: https://hexdocs.pm/phoenix/overview.html
- Docs: https://hexdocs.pm/phoenix
- Forum: https://elixirforum.com/c/phoenix-forum
- Source: https://github.com/phoenixframework/phoenix
