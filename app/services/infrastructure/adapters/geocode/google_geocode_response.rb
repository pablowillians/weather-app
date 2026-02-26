module Services
  module Infrastructure
    module Adapters
      module Geocode
        # ## Google Geocode API response
        #
        # Wraps the raw JSON from the Geocode API and exposes:
        #
        # - **latitude** / **longitude** — from `geometry.location`
        # - **zipcode** — from the first `postal_code` in `address_components`
        # - **source** — `:api_response` or `:cached_response`
        #
        # ### Example
        #
        # ```ruby
        # response = GoogleGeocodeResponse.new(api_json, :api_response)
        # response.latitude  # => -23.5505
        # response.zipcode  # => "01310"
        # ```
        class GoogleGeocodeResponse
          attr_reader :data, :source

          # Builds a response from raw **data** and **source**.
          #
          # - **data** — Hash from the Geocode API (must not be `nil`).
          # - **source** — Symbol `:api_response` or `:cached_response`.
          def initialize(data, source)
            raise ArgumentError, "Data cannot be nil" if data.nil?
            raise ArgumentError, "Source must be a symbol" unless source.is_a?(Symbol)

            @data = data
            @source = source
          end

          # Latitude from the first result's `geometry.location.lat`.
          def latitude
            result.dig("geometry", "location", "lat")
          end

          # Longitude from the first result's `geometry.location.lng`.
          def longitude
            result.dig("geometry", "location", "lng")
          end

          # Postal code from the first result's `address_components` (type `postal_code`), or `nil`.
          def zipcode
            component = result["address_components"]&.find { |c| c["types"]&.include?("postal_code") }
            component&.dig("short_name")
          end

          private

          def result
            @data["results"]&.first || {}
          end
        end
      end
    end
  end
end
