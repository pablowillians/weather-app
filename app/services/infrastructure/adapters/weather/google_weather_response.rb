module Services
  module Infrastructure
    module Adapters
      module Weather
        # ## Google Weather API response
        #
        # Wraps the raw JSON from the Weather API and exposes:
        #
        # - **data** — Hash from the API (e.g. `currentTime`, `temperature`, `weatherCondition`, `relativeHumidity`).
        # - **source** — `:api_response` or `:cached_response`
        #
        # ### Example
        #
        # ```ruby
        # response = GoogleCurrentWeatherResponse.new(api_json, :api_response)
        # response.data["temperature"]["degrees"]  # => 25.3
        # response.source  # => :api_response
        # ```
        class GoogleWeatherResponse
          attr_reader :data, :source

          # Builds a response from raw **data** and **source**.
          #
          # - **data** — Hash from the Weather API (must not be `nil`).
          # - **source** — Symbol `:api_response` or `:cached_response`.
          def initialize(data, source)
            raise ArgumentError, "Data cannot be nil" if data.nil?
            raise ArgumentError, "Source must be a symbol" unless source.is_a?(Symbol)

            @data = data
            @source = source
          end
        end
      end
    end
  end
end
