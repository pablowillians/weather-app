# frozen_string_literal: true

module Services
  module Domains
    module Weather
      # Value object: a single day in the daily forecast.
      class DailyForecastEntry
        attr_reader :display_date,
                    :max_temperature_degrees, :min_temperature_degrees,
                    :weather_condition

        def initialize(
          display_date: nil,
          max_temperature_degrees:,
          min_temperature_degrees:,
          weather_condition:
        )
          @display_date = display_date
          @max_temperature_degrees = max_temperature_degrees
          @min_temperature_degrees = min_temperature_degrees
          @weather_condition = weather_condition
          freeze
        end
      end
    end
  end
end
