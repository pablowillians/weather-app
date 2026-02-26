# frozen_string_literal: true

module Services
  module Domains
    module Weather
      # Aggregate root: weather at a location — groups a Geocode::Location,
      # CurrentWeather, and the hourly/daily forecast entry arrays.
      # Forecast arrays are wrapped with +Array()+ so +nil+ is safe.
      class WeatherAtLocation
        attr_reader :location, :current_weather, :hourly_forecast_entries, :daily_forecast_entries

        def initialize(
          location:,
          current_weather:,
          hourly_forecast_entries:,
          daily_forecast_entries:
        )
          @location = location
          @current_weather = current_weather
          @hourly_forecast_entries = Array(hourly_forecast_entries).freeze
          @daily_forecast_entries = Array(daily_forecast_entries).freeze
          freeze
        end
      end
    end
  end
end
