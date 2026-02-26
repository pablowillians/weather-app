# frozen_string_literal: true

module Services
  # ## Domains
  #
  # **Geocode:** Location (lat, lng, zipcode, formatted_address). No dependencies.
  #
  # **Weather — who contains what:**
  #
  # - CurrentWeather → 1× WeatherCondition (+ temp, feels-like)
  # - HourlyForecastEntry → 1× WeatherCondition (+ temp, feels-like)
  # - DailyForecastEntry → 1× WeatherCondition (+ max/min temp)
  #
  # **WeatherAtLocation** (aggregate) → Location + CurrentWeather + HourlyForecastEntry[] + DailyForecastEntry[].
  #
  # Standalone: WeatherCondition (description, type, icon).
  #
  module Domains
  end
end
