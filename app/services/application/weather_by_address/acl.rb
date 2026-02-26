# frozen_string_literal: true

module Services
  module Application
    class WeatherByAddress
      # ## ACL (Anti-Corruption Layer)
      #
      # Shields the domain from external API data structures by translating
      # raw response hashes into domain value objects. This is the classic
      # DDD Anti-Corruption Layer pattern: the domain never sees Google's
      # JSON shape — only clean value objects.
      #
      # All public methods are pure mappings — no side-effects, no I/O.
      #
      # ### Example
      #
      # ```ruby
      # acl      = Services::Application::WeatherByAddress::Acl.new
      # location = acl.build_location(geocode_response)
      # current  = acl.build_current_weather(raw_hash)
      # ```
      class Acl
        # @param geocode_response [#latitude, #longitude, #zipcode, #formatted_address]
        # @return [Domains::Geocode::Location]
        def build_location(geocode_response)
          Domains::Geocode::Location.new(
            latitude: geocode_response.latitude,
            longitude: geocode_response.longitude,
            zipcode: geocode_response.zipcode,
            formatted_address: geocode_response.formatted_address
          )
        end

        # @param data [Hash] raw current-weather payload from the API
        # @return [Domains::Weather::CurrentWeather]
        def build_current_weather(data)
          time_zone_id = data.dig("timeZone", "id").to_s.presence || "UTC"

          Domains::Weather::CurrentWeather.new(
            current_time: parse_time(data["currentTime"]),
            time_zone_id: time_zone_id,
            is_daytime: data["isDaytime"],
            weather_condition: build_weather_condition(data["weatherCondition"]),
            temperature_degrees: data.dig("temperature", "degrees").to_f,
            feels_like_degrees: data.dig("feelsLikeTemperature", "degrees")&.to_f
          )
        end

        # @param data [Hash] raw hourly-forecast payload from the API
        # @return [Array<Domains::Weather::HourlyForecastEntry>]
        def build_hourly_forecast_entries(data)
          (data["forecastHours"] || []).map { |h| build_hourly_entry(h) }
        end

        # @param data [Hash] raw daily-forecast payload from the API
        # @return [Array<Domains::Weather::DailyForecastEntry>]
        def build_daily_forecast_entries(data)
          (data["forecastDays"] || []).map { |d| build_daily_entry(d) }
        end

        private

        def build_hourly_entry(hour)
          Domains::Weather::HourlyForecastEntry.new(
            display_date_time: format_display_date_time(hour["displayDateTime"]),
            is_daytime: hour["isDaytime"],
            weather_condition: build_weather_condition(hour["weatherCondition"]),
            temperature_degrees: hour.dig("temperature", "degrees").to_f,
            feels_like_degrees: hour.dig("feelsLikeTemperature", "degrees")&.to_f
          )
        end

        def build_daily_entry(day)
          daytime = day["daytimeForecast"] || {}

          Domains::Weather::DailyForecastEntry.new(
            display_date: format_display_date(day["displayDate"]),
            max_temperature_degrees: day.dig("maxTemperature", "degrees").to_f,
            min_temperature_degrees: day.dig("minTemperature", "degrees").to_f,
            weather_condition: build_weather_condition(daytime["weatherCondition"])
          )
        end

        def build_weather_condition(hash)
          return Domains::Weather::WeatherCondition.new(description: "Unknown", type: "UNKNOWN") if hash.blank?

          Domains::Weather::WeatherCondition.new(
            description: hash.dig("description", "text").to_s.presence || "Unknown",
            type: hash["type"].to_s.presence || "UNKNOWN",
            icon_base_uri: hash["iconBaseUri"].to_s.presence
          )
        end

        def parse_time(value)
          return nil if value.blank?
          Time.zone.parse(value.to_s)
        end

        def format_display_date_time(display_date_time)
          return nil if display_date_time.blank?

          y = display_date_time["year"]
          m = display_date_time["month"]
          d = display_date_time["day"]
          h = display_date_time["hours"]
          return nil if y.nil? || m.nil? || d.nil?

          "#{y}-#{m.to_s.rjust(2, '0')}-#{d.to_s.rjust(2, '0')} #{h.to_s.rjust(2, '0')}:00"
        end

        def format_display_date(display_date)
          return nil if display_date.blank?

          y = display_date["year"]
          m = display_date["month"]
          d = display_date["day"]
          return nil if y.nil? || m.nil? || d.nil?

          "#{y}-#{m.to_s.rjust(2, '0')}-#{d.to_s.rjust(2, '0')}"
        end
      end
    end
  end
end
