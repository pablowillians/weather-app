# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Domains::Weather::WeatherAtLocation do
  let(:location) do
    Services::Domains::Geocode::Location.new(latitude: -23.56, longitude: -46.65, zipcode: "01310-100")
  end
  let(:current_weather) do
    condition = Services::Domains::Weather::WeatherCondition.new(description: "Sunny", type: "CLEAR")
    Services::Domains::Weather::CurrentWeather.new(
      current_time: Time.zone.now,
      time_zone_id: "America/Sao_Paulo",
      is_daytime: true,
      weather_condition: condition,
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
    condition = Services::Domains::Weather::WeatherCondition.new(description: "Sunny", type: "CLEAR")
    Services::Domains::Weather::DailyForecastEntry.new(
      max_temperature_degrees: 30.0,
      min_temperature_degrees: 18.0,
      weather_condition: condition
    )
  end

  describe "#initialize" do
    it "sets location, current_weather, hourly_forecast_entries, daily_forecast_entries" do
      aggregate = described_class.new(
        location: location,
        current_weather: current_weather,
        hourly_forecast_entries: [ hourly_entry ],
        daily_forecast_entries: [ daily_entry ]
      )

      expect(aggregate.location).to eq(location)
      expect(aggregate.current_weather).to eq(current_weather)
      expect(aggregate.hourly_forecast_entries).to eq([ hourly_entry ])
      expect(aggregate.daily_forecast_entries).to eq([ daily_entry ])
    end

    it "freezes the entry arrays" do
      aggregate = described_class.new(
        location: location,
        current_weather: current_weather,
        hourly_forecast_entries: [ hourly_entry ],
        daily_forecast_entries: [ daily_entry ]
      )

      expect(aggregate.hourly_forecast_entries).to be_frozen
      expect(aggregate.daily_forecast_entries).to be_frozen
    end

    it "coerces nil forecast entries to empty arrays" do
      aggregate = described_class.new(
        location: location,
        current_weather: current_weather,
        hourly_forecast_entries: nil,
        daily_forecast_entries: nil
      )

      expect(aggregate.hourly_forecast_entries).to eq([])
      expect(aggregate.daily_forecast_entries).to eq([])
    end
  end

  describe "immutability" do
    it "is frozen" do
      aggregate = described_class.new(
        location: location,
        current_weather: current_weather,
        hourly_forecast_entries: [],
        daily_forecast_entries: []
      )

      expect(aggregate).to be_frozen
    end
  end
end
