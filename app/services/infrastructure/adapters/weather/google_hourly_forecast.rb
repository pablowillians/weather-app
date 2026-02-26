module Services
  module Infrastructure
    module Adapters
      module Weather
        # ## Google Weather API — Hourly forecast
        #
        # Adapter for the [Hourly Forecast](https://developers.google.com/maps/documentation/weather/hourly-forecast) endpoint.
        # Returns a **GoogleHourlyForecastResponse** with the next **12 hours** of forecast.
        class GoogleHourlyForecast < GoogleWeatherBase
          private

          def base_url = "https://weather.googleapis.com/v1/forecast/hours:lookup"
          def cache_prefix = "google_hourly_forecast"
          def response_class = GoogleHourlyForecastResponse
          def response_key = "forecastHours"
          def error_label = "hourly forecast"
          def extra_params = { hours: 12 }
        end
      end
    end
  end
end
