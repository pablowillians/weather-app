# frozen_string_literal: true

module Services
  module Domains
    module Weather
      # Value object: a single hour in the hourly forecast.
      class HourlyForecastEntry
        attr_reader :display_date_time, :is_daytime,
                    :weather_condition, :temperature_degrees, :feels_like_degrees

        def initialize(
          display_date_time: nil,
          is_daytime: nil,
          weather_condition:,
          temperature_degrees:,
          feels_like_degrees: nil
        )
          @display_date_time = display_date_time
          @is_daytime = is_daytime
          @weather_condition = weather_condition
          @temperature_degrees = temperature_degrees
          @feels_like_degrees = feels_like_degrees
          freeze
        end
      end
    end
  end
end
