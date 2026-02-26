# frozen_string_literal: true

module Services
  module Application
    class WeatherByAddress
      # ## WeatherByAddress Result
      #
      # Thin wrapper returned by `WeatherByAddress#call`. Delegates weather
      # fields to **WeatherAtLocation** and adds per-adapter source tracking
      # (`:api_response` / `:cached_response`).
      #
      # ### Example
      #
      # ```ruby
      # result = Services::Application::WeatherByAddress.new.call("São Paulo")
      # result.location.latitude          # => -23.55
      # result.current_weather            # => CurrentWeather
      # result.from_cache?(:geocode)      # => false
      # result.sources[:current_weather]  # => :api_response
      # ```
      class Result
        attr_reader :weather_at_location, :sources

        delegate :location, :current_weather, :hourly_forecast_entries, :daily_forecast_entries,
                 to: :weather_at_location

        def initialize(weather_at_location:, sources:)
          @weather_at_location = weather_at_location
          @sources = sources.freeze
          freeze
        end

        def from_cache?(key)
          sources[key] == :cached_response
        end
      end
    end
  end
end
