module Services
  module Infrastructure
    module Adapters
      module Weather
        # ## Google Weather API — Daily forecast
        #
        # Adapter for the [Daily Forecast](https://developers.google.com/maps/documentation/weather/daily-forecast) endpoint.
        # Returns a **GoogleDailyForecastResponse** with the next **7 days** of forecast.
        class GoogleDailyForecast < GoogleWeatherBase
          private

          def base_url = "https://weather.googleapis.com/v1/forecast/days:lookup"
          def cache_prefix = "google_daily_forecast"
          def response_class = GoogleDailyForecastResponse
          def response_key = "forecastDays"
          def error_label = "daily forecast"
          def extra_params = { days: 7 }
        end
      end
    end
  end
end
