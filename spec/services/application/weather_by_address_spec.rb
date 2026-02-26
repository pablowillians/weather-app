# frozen_string_literal: true

# Application layer specs for WeatherByAddress.
# Adapters and ACL are stubbed; only orchestration, delegation, and error
# translation are tested. Data mapping is covered in WeatherByAddress::Acl spec.
require "rails_helper"

RSpec.describe Services::Application::WeatherByAddress do
  let(:address) { "São Paulo, Brazil" }

  let(:geocode_adapter) { instance_double(Services::Infrastructure::Adapters::Geocode::GoogleGeocode) }
  let(:current_weather_adapter) { instance_double(Services::Infrastructure::Adapters::Weather::GoogleCurrentWeather) }
  let(:hourly_forecast_adapter) { instance_double(Services::Infrastructure::Adapters::Weather::GoogleHourlyForecast) }
  let(:daily_forecast_adapter) { instance_double(Services::Infrastructure::Adapters::Weather::GoogleDailyForecast) }
  let(:acl) { instance_double(Services::Application::WeatherByAddress::Acl) }

  let(:geocode_response) do
    Services::Infrastructure::Adapters::Geocode::GoogleGeocodeResponse.new(
      load_geocode_fixture("success_with_zipcode"),
      :api_response
    )
  end

  let(:location) do
    Services::Domains::Geocode::Location.new(
      latitude: geocode_response.latitude,
      longitude: geocode_response.longitude,
      zipcode: geocode_response.zipcode,
      formatted_address: geocode_response.formatted_address
    )
  end

  let(:current_weather_response) do
    Services::Infrastructure::Adapters::Weather::GoogleCurrentWeatherResponse.new(
      load_weather_fixture("current_weather_success"),
      :api_response
    )
  end

  let(:hourly_forecast_response) do
    Services::Infrastructure::Adapters::Weather::GoogleHourlyForecastResponse.new(
      load_weather_fixture("hourly_forecast_success"),
      :api_response
    )
  end

  let(:daily_forecast_response) do
    Services::Infrastructure::Adapters::Weather::GoogleDailyForecastResponse.new(
      load_weather_fixture("daily_forecast_success"),
      :api_response
    )
  end

  let(:current_weather) do
    Services::Domains::Weather::CurrentWeather.new(
      current_time: Time.current,
      time_zone_id: "America/Sao_Paulo",
      is_daytime: true,
      weather_condition: Services::Domains::Weather::WeatherCondition.new(description: "Partly cloudy", type: "PARTLY_CLOUDY"),
      temperature_degrees: 25.3,
      feels_like_degrees: 26.1
    )
  end

  let(:hourly_entries) do
    [
      Services::Domains::Weather::HourlyForecastEntry.new(
        weather_condition: Services::Domains::Weather::WeatherCondition.new(description: "Partly cloudy", type: "PARTLY_CLOUDY"),
        temperature_degrees: 25.3
      )
    ]
  end

  let(:daily_entries) do
    [
      Services::Domains::Weather::DailyForecastEntry.new(
        weather_condition: Services::Domains::Weather::WeatherCondition.new(description: "Partly cloudy", type: "PARTLY_CLOUDY"),
        max_temperature_degrees: 28.5,
        min_temperature_degrees: 19.3
      )
    ]
  end

  let(:service) do
    described_class.new(
      geocode_adapter: geocode_adapter,
      current_weather_adapter: current_weather_adapter,
      hourly_forecast_adapter: hourly_forecast_adapter,
      daily_forecast_adapter: daily_forecast_adapter,
      acl: acl
    )
  end

  before do
    allow(geocode_adapter).to receive(:call).with(address).and_return(geocode_response)
    allow(current_weather_adapter).to receive(:call).and_return(current_weather_response)
    allow(hourly_forecast_adapter).to receive(:call).and_return(hourly_forecast_response)
    allow(daily_forecast_adapter).to receive(:call).and_return(daily_forecast_response)

    allow(acl).to receive(:build_location).with(geocode_response).and_return(location)
    allow(acl).to receive(:build_current_weather).with(current_weather_response.data).and_return(current_weather)
    allow(acl).to receive(:build_hourly_forecast_entries).with(hourly_forecast_response.data).and_return(hourly_entries)
    allow(acl).to receive(:build_daily_forecast_entries).with(daily_forecast_response.data).and_return(daily_entries)
  end

  describe "#call" do
    it "returns a Result wrapping a WeatherAtLocation" do
      result = service.call(address)

      expect(result).to be_a(described_class::Result)
      expect(result.weather_at_location).to be_a(Services::Domains::Weather::WeatherAtLocation)
    end

    it "delegates to the ACL for domain object construction" do
      service.call(address)

      expect(acl).to have_received(:build_location).with(geocode_response)
      expect(acl).to have_received(:build_current_weather).with(current_weather_response.data)
      expect(acl).to have_received(:build_hourly_forecast_entries).with(hourly_forecast_response.data)
      expect(acl).to have_received(:build_daily_forecast_entries).with(daily_forecast_response.data)
    end

    it "geocodes the address first" do
      service.call(address)

      expect(geocode_adapter).to have_received(:call).with(address).once
    end

    it "strips the address before passing to geocode" do
      allow(geocode_adapter).to receive(:call).with(address).and_return(geocode_response)

      service.call("  #{address}  ")

      expect(geocode_adapter).to have_received(:call).with(address)
    end

    it "passes coordinates and zipcode from geocode to all three weather adapters" do
      service.call(address)

      expected_args = [ location.latitude, location.longitude, { zipcode: location.zipcode } ]
      expect(current_weather_adapter).to have_received(:call).with(*expected_args)
      expect(hourly_forecast_adapter).to have_received(:call).with(*expected_args)
      expect(daily_forecast_adapter).to have_received(:call).with(*expected_args)
    end

    it "exposes data sources for each adapter call" do
      result = service.call(address)

      expect(result.sources[:geocode]).to eq(:api_response)
      expect(result.sources[:current_weather]).to eq(:api_response)
      expect(result.sources[:hourly_forecast]).to eq(:api_response)
      expect(result.sources[:daily_forecast]).to eq(:api_response)
    end

    it "exposes from_cache? helper" do
      result = service.call(address)

      expect(result.from_cache?(:geocode)).to be false
    end

    it "exposes location, current_weather, and forecast entries via delegation" do
      result = service.call(address)

      expect(result.location).to eq(location)
      expect(result.current_weather).to eq(current_weather)
      expect(result.hourly_forecast_entries).to eq(hourly_entries)
      expect(result.daily_forecast_entries).to eq(daily_entries)
    end
  end

  describe "error translation" do
    context "when geocode raises NotFoundError" do
      before do
        allow(geocode_adapter).to receive(:call).and_raise(
          Services::Infrastructure::Adapters::Geocode::NotFoundError,
          "No Google Geocode data found for address: #{address}"
        )
      end

      it "translates to AddressNotFoundError" do
        expect { service.call(address) }.to raise_error(
          Services::Application::AddressNotFoundError,
          "No Google Geocode data found for address: #{address}"
        )
      end

      it "does not call weather adapters" do
        service.call(address)
      rescue Services::Application::AddressNotFoundError
        expect(current_weather_adapter).not_to have_received(:call)
        expect(hourly_forecast_adapter).not_to have_received(:call)
        expect(daily_forecast_adapter).not_to have_received(:call)
      end
    end

    context "when a weather adapter raises NotFoundError" do
      before do
        allow(current_weather_adapter).to receive(:call).and_raise(
          Services::Infrastructure::Adapters::Weather::NotFoundError,
          "No current weather data found"
        )
      end

      it "translates to WeatherNotFoundError" do
        expect { service.call(address) }.to raise_error(
          Services::Application::WeatherNotFoundError,
          "No current weather data found"
        )
      end
    end

    context "when geocode raises a generic Error" do
      before do
        allow(geocode_adapter).to receive(:call).and_raise(
          Services::Infrastructure::Adapters::Geocode::Error,
          "Failed to fetch Google Geocode data"
        )
      end

      it "translates to ServiceError" do
        expect { service.call(address) }.to raise_error(
          Services::Application::ServiceError,
          "Failed to fetch Google Geocode data"
        )
      end
    end

    context "when a weather adapter raises a generic Error" do
      before do
        allow(current_weather_adapter).to receive(:call).and_raise(
          Services::Infrastructure::Adapters::Weather::Error,
          "Failed to fetch current weather data"
        )
      end

      it "translates to ServiceError" do
        expect { service.call(address) }.to raise_error(
          Services::Application::ServiceError,
          "Failed to fetch current weather data"
        )
      end
    end
  end
end
