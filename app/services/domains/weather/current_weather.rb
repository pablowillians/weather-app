# frozen_string_literal: true

module Services
  module Domains
    module Weather
      # Value object: snapshot of current weather conditions at a point in time.
      # +time_zone_id+ is coerced to a frozen string.
      class CurrentWeather
        attr_reader :current_time, :time_zone_id, :is_daytime, :weather_condition,
                    :temperature_degrees, :feels_like_degrees

        def initialize(
          current_time:,
          time_zone_id:,
          is_daytime:,
          weather_condition:,
          temperature_degrees:,
          feels_like_degrees: nil
        )
          @current_time = current_time
          @time_zone_id = time_zone_id.to_s.freeze
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
