# frozen_string_literal: true

# Anti-Corruption Layer specs: verifies that raw API payloads are correctly
# translated into domain value objects, shielding the domain from external formats.
require "rails_helper"

RSpec.describe Services::Application::WeatherByAddress::Acl do
  subject(:acl) { described_class.new }

  describe "#build_location" do
    let(:geocode_response) do
      Services::Infrastructure::Adapters::Geocode::GoogleGeocodeResponse.new(
        load_geocode_fixture("success_with_zipcode"),
        :api_response
      )
    end

    it "returns a Location domain object" do
      location = acl.build_location(geocode_response)

      expect(location).to be_a(Services::Domains::Geocode::Location)
    end

    it "maps latitude and longitude from the geocode response" do
      location = acl.build_location(geocode_response)

      expect(location.latitude).to eq(geocode_response.latitude)
      expect(location.longitude).to eq(geocode_response.longitude)
    end

    it "maps zipcode from the geocode response" do
      location = acl.build_location(geocode_response)

      expect(location.zipcode).to eq("01310-100")
    end

    it "maps formatted_address from the geocode response" do
      location = acl.build_location(geocode_response)

      expect(location.formatted_address).to eq(geocode_response.formatted_address)
    end
  end

  describe "#build_current_weather" do
    let(:data) { load_weather_fixture("current_weather_success") }

    it "returns a CurrentWeather domain object" do
      result = acl.build_current_weather(data)

      expect(result).to be_a(Services::Domains::Weather::CurrentWeather)
    end

    it "maps temperature and feels-like" do
      result = acl.build_current_weather(data)

      expect(result.temperature_degrees).to eq(25.3)
      expect(result.feels_like_degrees).to eq(26.1)
    end

    it "maps time zone from nested payload" do
      result = acl.build_current_weather(data)

      expect(result.time_zone_id).to eq("America/Sao_Paulo")
    end

    it "maps is_daytime flag" do
      result = acl.build_current_weather(data)

      expect(result.is_daytime).to be true
    end

    it "maps the weather condition" do
      result = acl.build_current_weather(data)

      expect(result.weather_condition.description).to eq("Partly cloudy")
      expect(result.weather_condition.type).to eq("PARTLY_CLOUDY")
      expect(result.weather_condition.icon_base_uri).to eq("https://maps.gstatic.com/weather/v1/partly_cloudy")
    end

    it "parses currentTime as a Time object" do
      result = acl.build_current_weather(data)

      expect(result.current_time).to be_a(Time)
    end

    context "when timeZone is missing" do
      before { data.delete("timeZone") }

      it "defaults to UTC" do
        result = acl.build_current_weather(data)

        expect(result.time_zone_id).to eq("UTC")
      end
    end

    context "when feelsLikeTemperature is missing" do
      before { data.delete("feelsLikeTemperature") }

      it "sets feels_like_degrees to nil" do
        result = acl.build_current_weather(data)

        expect(result.feels_like_degrees).to be_nil
      end
    end

    context "when weatherCondition is missing" do
      before { data.delete("weatherCondition") }

      it "returns an unknown weather condition" do
        result = acl.build_current_weather(data)

        expect(result.weather_condition.description).to eq("Unknown")
        expect(result.weather_condition.type).to eq("UNKNOWN")
      end
    end
  end

  describe "#build_hourly_forecast_entries" do
    let(:data) { load_weather_fixture("hourly_forecast_success") }

    it "returns an array of HourlyForecastEntry objects" do
      entries = acl.build_hourly_forecast_entries(data)

      expect(entries).to all(be_a(Services::Domains::Weather::HourlyForecastEntry))
    end

    it "maps all entries from the payload" do
      entries = acl.build_hourly_forecast_entries(data)

      expect(entries.size).to eq(2)
    end

    it "maps temperature and weather condition for each entry" do
      first, second = acl.build_hourly_forecast_entries(data)

      expect(first.temperature_degrees).to eq(25.3)
      expect(first.weather_condition.description).to eq("Partly cloudy")

      expect(second.temperature_degrees).to eq(24.1)
      expect(second.weather_condition.description).to eq("Cloudy")
    end

    it "formats display_date_time as YYYY-MM-DD HH:00" do
      first = acl.build_hourly_forecast_entries(data).first

      expect(first.display_date_time).to eq("2025-01-28 19:00")
    end

    it "maps is_daytime flag" do
      first = acl.build_hourly_forecast_entries(data).first

      expect(first.is_daytime).to be true
    end

    it "maps feels_like_degrees" do
      first = acl.build_hourly_forecast_entries(data).first

      expect(first.feels_like_degrees).to eq(26.1)
    end

    context "when forecastHours is missing" do
      before { data.delete("forecastHours") }

      it "returns an empty array" do
        expect(acl.build_hourly_forecast_entries(data)).to eq([])
      end
    end

    context "when displayDateTime is missing from an entry" do
      before { data["forecastHours"].first.delete("displayDateTime") }

      it "sets display_date_time to nil" do
        first = acl.build_hourly_forecast_entries(data).first

        expect(first.display_date_time).to be_nil
      end
    end
  end

  describe "#build_daily_forecast_entries" do
    let(:data) { load_weather_fixture("daily_forecast_success") }

    it "returns an array of DailyForecastEntry objects" do
      entries = acl.build_daily_forecast_entries(data)

      expect(entries).to all(be_a(Services::Domains::Weather::DailyForecastEntry))
    end

    it "maps all entries from the payload" do
      entries = acl.build_daily_forecast_entries(data)

      expect(entries.size).to eq(2)
    end

    it "maps max and min temperatures" do
      first = acl.build_daily_forecast_entries(data).first

      expect(first.max_temperature_degrees).to eq(28.5)
      expect(first.min_temperature_degrees).to eq(19.3)
    end

    it "uses the daytime forecast weather condition" do
      first = acl.build_daily_forecast_entries(data).first

      expect(first.weather_condition.description).to eq("Partly cloudy")
      expect(first.weather_condition.type).to eq("PARTLY_CLOUDY")
    end

    it "formats display_date as YYYY-MM-DD" do
      first = acl.build_daily_forecast_entries(data).first

      expect(first.display_date).to eq("2025-01-28")
    end

    context "when forecastDays is missing" do
      before { data.delete("forecastDays") }

      it "returns an empty array" do
        expect(acl.build_daily_forecast_entries(data)).to eq([])
      end
    end

    context "when daytimeForecast is missing from an entry" do
      before { data["forecastDays"].first.delete("daytimeForecast") }

      it "returns an unknown weather condition" do
        first = acl.build_daily_forecast_entries(data).first

        expect(first.weather_condition.description).to eq("Unknown")
        expect(first.weather_condition.type).to eq("UNKNOWN")
      end
    end

    context "when displayDate is missing from an entry" do
      before { data["forecastDays"].first.delete("displayDate") }

      it "sets display_date to nil" do
        first = acl.build_daily_forecast_entries(data).first

        expect(first.display_date).to be_nil
      end
    end
  end
end
