# frozen_string_literal: true

module Services
  # ## Infrastructure
  #
  # Namespace for infrastructure concerns: adapters to external APIs, third-party
  # services, and integration with the outside world. Code here is organized by
  # domain (e.g. geocoding, weather) rather than by use case.
  #
  # ### Contents
  #
  # - **Adapters** — External API adapters (Geocode, Weather). Each adapter wraps
  #   a provider (e.g. Google), handles HTTP, caching, and returns a typed response.
  module Infrastructure
  end
end
