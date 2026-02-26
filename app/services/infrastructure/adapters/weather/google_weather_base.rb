require "net/http"

module Services
  module Infrastructure
    module Adapters
      module Weather
        # ## Base class for Google Weather API adapters
        #
        # Subclasses must implement (private methods):
        #
        # - **base_url** — API endpoint URL
        # - **cache_prefix** — prefix for cache keys
        # - **response_class** — class to wrap the JSON response
        # - **response_key** — key in the JSON that indicates success (e.g. `"currentTime"`, `"forecastHours"`)
        # - **error_label** — string used in error messages (e.g. `"current weather"`)
        #
        # Optionally override **extra_params** for additional query parameters (e.g. `days: 7`, `hours: 12`).
        #
        # Responses are cached for 30 minutes per location.
        class GoogleWeatherBase
          def initialize
            @api_key = Rails.configuration.weather_app.google_places_api_key
            @cache = Rails.cache
          end

          # Fetches weather data for the given coordinates.
          #
          # ### Parameters
          #
          # - **latitude** (`Float`) — Latitude.
          # - **longitude** (`Float`) — Longitude.
          # - **zipcode** (`String`, optional) — When present, used in the cache key so nearby coordinates share the same cache entry.
          #
          # ### Returns
          #
          # An instance of the subclass's **response_class** (e.g. `GoogleCurrentWeatherResponse`).
          #
          # ### Raises
          #
          # - `NotFoundError` when the API returns no data for the coordinates.
          # - `Error` when the HTTP request fails.
          def call(latitude, longitude, zipcode: nil)
            cache_key = build_cache_key(latitude, longitude, zipcode)

            cached_response = @cache.read(cache_key)
            return response_class.new(cached_response, :cached_response) if cached_response.present?

            uri = URI.parse(base_url)
            uri.query = URI.encode_www_form(
              { key: @api_key, "location.latitude": latitude, "location.longitude": longitude }.merge(extra_params)
            )

            response = Net::HTTP.get_response(uri)
            raise Error, "Failed to fetch #{error_label} data" unless response.is_a?(Net::HTTPSuccess)

            response_data = JSON.parse(response.body)
            raise NotFoundError, "No #{error_label} data found for coordinates: #{latitude}, #{longitude}" unless response_data[response_key].present?

            @cache.write(cache_key, response_data, expires_in: 30.minutes)
            response_class.new(response_data, :api_response)
          end

          private

          def build_cache_key(latitude, longitude, zipcode)
            zipcode.present? ? "#{cache_prefix}_#{zipcode}" : "#{cache_prefix}_#{latitude}_#{longitude}"
          end

          def extra_params = {}
          def base_url = raise(NotImplementedError)
          def cache_prefix = raise(NotImplementedError)
          def response_class = raise(NotImplementedError)
          def response_key = raise(NotImplementedError)
          def error_label = raise(NotImplementedError)
        end
      end
    end
  end
end
