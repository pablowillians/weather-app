# frozen_string_literal: true

module Services
  module Infrastructure
    module Adapters
      # ## Weather
      #
      # Namespace for weather adapters. Fetches current conditions and forecasts
      # by coordinates (latitude/longitude), using providers such as the Google Weather API.
      #
      # ### Contents
      #
      # **Adapters (use #call with latitude, longitude, optional zipcode):**
      #
      # - **GoogleCurrentWeather** — Current conditions at the given coordinates.
      # - **GoogleDailyForecast** — Next 7 days of daily forecast.
      # - **GoogleHourlyForecast** — Next 12 hours of hourly forecast.
      #
      # **Base and responses:**
      #
      # - **GoogleWeatherBase** — Base class for Google Weather adapters; subclasses implement endpoint details.
      # - **GoogleWeatherResponse** — Base response wrapper (**data**, **source**).
      # - **GoogleCurrentWeatherResponse**, **GoogleDailyForecastResponse**, **GoogleHourlyForecastResponse** — Response classes per endpoint.
      #
      # **Errors:**
      #
      # - **Error** — Base exception when the request fails.
      # - **NotFoundError** — Raised when no weather data is found for the coordinates.
      module Weather
      end
    end
  end
end
