# frozen_string_literal: true

# Unit specs for WeatherByAddress::Result: initialization, immutability,
# delegation to WeatherAtLocation, and from_cache? source tracking.
require "rails_helper"

RSpec.describe Services::Application::WeatherByAddress::Result do
  let(:weather_condition) do
    Services::Domains::Weather::WeatherCondition.new(description: "Sunny", type: "CLEAR")
  end

  let(:location) do
    Services::Domains::Geocode::Location.new(
      latitude: -23.55,
      longitude: -46.65,
      zipcode: "01310-100",
      formatted_address: "São Paulo, Brazil"
    )
  end

  let(:current_weather) do
    Services::Domains::Weather::CurrentWeather.new(
      current_time: Time.current,
      time_zone_id: "America/Sao_Paulo",
      is_daytime: true,
      weather_condition: weather_condition,
      temperature_degrees: 25.0
    )
  end

  let(:hourly_entry) do
    Services::Domains::Weather::HourlyForecastEntry.new(
      weather_condition: Services::Domains::Weather::WeatherCondition.new(description: "Clear", type: "CLEAR"),
      temperature_degrees: 24.0
    )
  end

  let(:daily_entry) do
    Services::Domains::Weather::DailyForecastEntry.new(
      weather_condition: Services::Domains::Weather::WeatherCondition.new(description: "Sunny", type: "CLEAR"),
      max_temperature_degrees: 30.0,
      min_temperature_degrees: 18.0
    )
  end

  let(:weather_at_location) do
    Services::Domains::Weather::WeatherAtLocation.new(
      location: location,
      current_weather: current_weather,
      hourly_forecast_entries: [ hourly_entry ],
      daily_forecast_entries: [ daily_entry ]
    )
  end

  let(:sources) do
    { geocode: :api_response, current_weather: :cached_response }
  end

  subject(:result) do
    described_class.new(weather_at_location: weather_at_location, sources: sources)
  end

  describe "#initialize" do
    it "sets weather_at_location and sources" do
      expect(result.weather_at_location).to eq(weather_at_location)
      expect(result.sources).to eq(sources)
    end
  end

  describe "immutability" do
    it "freezes the sources hash" do
      expect(result.sources).to be_frozen
    end

    it "freezes the Result itself" do
      expect(result).to be_frozen
    end
  end

  describe "delegation to weather_at_location" do
    it "delegates #location" do
      expect(result.location).to eq(location)
    end

    it "delegates #current_weather" do
      expect(result.current_weather).to eq(current_weather)
    end

    it "delegates #hourly_forecast_entries" do
      expect(result.hourly_forecast_entries).to eq([ hourly_entry ])
    end

    it "delegates #daily_forecast_entries" do
      expect(result.daily_forecast_entries).to eq([ daily_entry ])
    end
  end

  describe "#from_cache?" do
    it "returns true when source is :cached_response" do
      expect(result.from_cache?(:current_weather)).to be true
    end

    it "returns false when source is :api_response" do
      expect(result.from_cache?(:geocode)).to be false
    end

    it "returns false for unknown keys" do
      expect(result.from_cache?(:unknown_key)).to be false
    end
  end
end
