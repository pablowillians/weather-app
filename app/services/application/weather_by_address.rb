# frozen_string_literal: true

module Services
  module Application
    # ## Weather by address
    #
    # Application service that orchestrates a single use case:
    #
    # 1. Geocodes the address (latitude, longitude, optional zipcode).
    # 2. Fetches in parallel: current weather, hourly forecast, daily forecast.
    # 3. Maps raw responses to domain objects via **Acl** (Anti-Corruption Layer).
    # 4. Returns a **Result** wrapping a WeatherAtLocation domain aggregate
    #    plus data-source metadata (cache vs API) for each adapter call.
    #
    # ### Dependencies (injected)
    #
    # - **geocode_adapter** — `call(address)` → response with lat/lng/zipcode.
    # - **current_weather_adapter** — `call(lat, lng, zipcode:)` → response.
    # - **hourly_forecast_adapter** — `call(lat, lng, zipcode:)` → response.
    # - **daily_forecast_adapter** — `call(lat, lng, zipcode:)` → response.
    # - **acl** — Anti-Corruption Layer that translates raw API data into domain value objects.
    #
    # ### Errors
    #
    # Infrastructure adapter errors are translated to application-layer errors
    # so the presentation layer never depends on infrastructure details (DIP):
    #
    # - `AddressNotFoundError` — geocode found no results.
    # - `WeatherNotFoundError` — weather provider returned no data.
    # - `ServiceError` — any other adapter/network failure.
    #
    # ### Example
    #
    # ```ruby
    # service = Services::Application::WeatherByAddress.new
    # result  = service.call("São Paulo, Brazil")
    # result.location.latitude               # => -23.55
    # result.current_weather.temperature_degrees  # => 25.3
    # result.from_cache?(:geocode)           # => false
    # ```
    #
    # ### Nested constants (defined in weather_by_address/)
    #
    # - **WeatherByAddress::Acl** — Anti-Corruption Layer that shields the
    #   domain from external API data structures.
    # - **WeatherByAddress::Result** — Immutable wrapper that delegates weather
    #   fields to WeatherAtLocation and tracks per-adapter data sources.
    class WeatherByAddress
      def initialize(
        geocode_adapter: default_geocode_adapter,
        current_weather_adapter: default_current_weather_adapter,
        hourly_forecast_adapter: default_hourly_forecast_adapter,
        daily_forecast_adapter: default_daily_forecast_adapter,
        acl: Acl.new
      )
        @geocode_adapter = geocode_adapter
        @current_weather_adapter = current_weather_adapter
        @hourly_forecast_adapter = hourly_forecast_adapter
        @daily_forecast_adapter = daily_forecast_adapter
        @acl = acl
      end

      # @param address [String] address or place name to geocode
      # @return [Result]
      # @raise [AddressNotFoundError, WeatherNotFoundError, ServiceError]
      def call(address)
        geocode_response = @geocode_adapter.call(address.to_s.strip)
        location = @acl.build_location(geocode_response)

        current_resp, hourly_resp, daily_resp =
          fetch_weather_in_parallel(location.latitude, location.longitude, location.zipcode)

        weather = Domains::Weather::WeatherAtLocation.new(
          location: location,
          current_weather: @acl.build_current_weather(current_resp.data),
          hourly_forecast_entries: @acl.build_hourly_forecast_entries(hourly_resp.data),
          daily_forecast_entries: @acl.build_daily_forecast_entries(daily_resp.data)
        )

        Result.new(
          weather_at_location: weather,
          sources: {
            geocode: geocode_response.source,
            current_weather: current_resp.source,
            hourly_forecast: hourly_resp.source,
            daily_forecast: daily_resp.source
          }
        )
      rescue Infrastructure::Adapters::Geocode::NotFoundError => e
        raise AddressNotFoundError, e.message
      rescue Infrastructure::Adapters::Weather::NotFoundError => e
        raise WeatherNotFoundError, e.message
      rescue Infrastructure::Adapters::Geocode::Error,
             Infrastructure::Adapters::Weather::Error => e
        raise ServiceError, e.message
      end

      private

      def default_geocode_adapter
        Infrastructure::Adapters::Geocode::GoogleGeocode.new
      end

      def default_current_weather_adapter
        Infrastructure::Adapters::Weather::GoogleCurrentWeather.new
      end

      def default_hourly_forecast_adapter
        Infrastructure::Adapters::Weather::GoogleHourlyForecast.new
      end

      def default_daily_forecast_adapter
        Infrastructure::Adapters::Weather::GoogleDailyForecast.new
      end

      def fetch_weather_in_parallel(lat, lng, zip)
        [
          Thread.new { @current_weather_adapter.call(lat, lng, zipcode: zip) },
          Thread.new { @hourly_forecast_adapter.call(lat, lng, zipcode: zip) },
          Thread.new { @daily_forecast_adapter.call(lat, lng, zipcode: zip) }
        ].map(&:value)
      end
    end
  end
end
