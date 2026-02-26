require "net/http"

module Services
  module Infrastructure
    module Adapters
      module Geocode
        class Error < StandardError; end
        class NotFoundError < Error; end

        # ## Google Geocode API Adapter
        #
        # Fetches geocoding data from the [Google Geocode API](https://developers.google.com/maps/documentation/geocoding/start).
        # Responses are cached for 7 days per address.
        #
        # ### Example
        #
        # ```ruby
        # adapter = Services::Infrastructure::Adapters::Geocode::GoogleGeocode.new
        # response = adapter.call("São Paulo, Brazil")
        # response.latitude   # => -23.5505
        # response.longitude  # => -46.6333
        # response.zipcode    # => "01310-100"
        # response.source     # => :api_response
        # ```
        class GoogleGeocode
          BASE_URL = "https://maps.googleapis.com/maps/api/geocode/json"

          def initialize
            @api_key = Rails.configuration.weather_app.google_places_api_key
            @cache = Rails.cache
          end

          # Calls the Google Geocode API and returns a **GoogleGeocodeResponse**.
          #
          # ### Parameters
          #
          # - **address** (`String`) — Address or place name to geocode.
          #
          # ### Returns
          #
          # - `GoogleGeocodeResponse` with `latitude`, `longitude`, `zipcode` and `source` (`:api_response` or `:cached_response`).
          #
          # ### Raises
          #
          # - `NotFoundError` when the API returns no results for the address.
          # - `Error` when the HTTP request fails.
          def call(address)
            uri = URI.parse(BASE_URL)
            uri.query = URI.encode_www_form({
              key: @api_key,
              address: address
            })

            cached_response = @cache.read("google_geocode_#{address}")
            return GoogleGeocodeResponse.new(cached_response, :cached_response) if cached_response.present?

            response = Net::HTTP.get_response(uri)
            raise Error, "Failed to fetch Google Geocode data" unless response.is_a?(Net::HTTPSuccess)

            response_data = JSON.parse(response.body)
            raise NotFoundError, "No Google Geocode data found for address: #{address}" if response_data["status"] == "ZERO_RESULTS"

            @cache.write("google_geocode_#{address}", response_data, expires_in: 7.days)
            GoogleGeocodeResponse.new(response_data, :api_response)
          end
        end
      end
    end
  end
end
