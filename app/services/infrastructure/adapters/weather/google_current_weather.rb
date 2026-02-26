module Services
  module Infrastructure
    module Adapters
      module Weather
        # ## Google Weather API — Current conditions
        #
        # Fetches current weather from the [Current Conditions](https://developers.google.com/maps/documentation/weather/current-conditions) endpoint.
        # Responses are cached for 30 minutes per location.
        #
        # ### Example
        #
        # ```ruby
        # adapter = Services::Infrastructure::Adapters::Weather::GoogleCurrentWeather.new
        # response = adapter.call(-23.5505, -46.6333, zipcode: "01310-100")
        # response.data["temperature"]["degrees"]  # => 25.3
        # response.data["weatherCondition"]["description"]["text"]  # => "Partly cloudy"
        # response.source  # => :api_response
        # ```
        class GoogleCurrentWeather < GoogleWeatherBase
          private

          def base_url = "https://weather.googleapis.com/v1/currentConditions:lookup"
          def cache_prefix = "google_current_weather"
          def response_class = GoogleCurrentWeatherResponse
          def response_key = "currentTime"
          def error_label = "current weather"
        end
      end
    end
  end
end
