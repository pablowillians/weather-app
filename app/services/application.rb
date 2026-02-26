# frozen_string_literal: true

module Services
  # ## Application
  #
  # Application services orchestrate use cases: they call infrastructure adapters
  # and domain logic, then return results to the presentation layer.
  #
  # ### Errors
  #
  # Application-layer errors isolate the presentation layer from infrastructure
  # details (Dependency Inversion). Controllers rescue these instead of adapter
  # errors directly.
  #
  # - **AddressNotFoundError** — the geocode provider found no results.
  # - **WeatherNotFoundError** — the weather provider found no data.
  # - **ServiceError** — any other infrastructure failure (network, auth, etc.).
  #
  # ### Contents
  #
  # - **WeatherByAddress** — Orchestrates geocode → fetch → map → result.
  #   - **WeatherByAddress::Acl** — Anti-Corruption Layer that shields the
  #     domain from external API data structures.
  #   - **WeatherByAddress::Result** — Immutable wrapper that delegates weather
  #     fields to WeatherAtLocation and tracks per-adapter data sources.
  module Application
    class Error < StandardError; end
    class AddressNotFoundError < Error; end
    class WeatherNotFoundError < Error; end
    class ServiceError < Error; end
  end
end
