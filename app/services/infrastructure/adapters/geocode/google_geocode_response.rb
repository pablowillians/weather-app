module Services
  module Infrastructure
    module Adapters
      module Geocode
        class GoogleGeocodeResponse
          attr_reader :data, :source

          def initialize(data, source)
            raise ArgumentError, "Data cannot be nil" if data.nil?
            raise ArgumentError, "Source must be a symbol" unless source.is_a?(Symbol)

            @data = data
            @source = source
          end

          def latitude
            result.dig("geometry", "location", "lat")
          end

          def longitude
            result.dig("geometry", "location", "lng")
          end

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
