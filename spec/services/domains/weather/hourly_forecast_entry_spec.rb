# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Domains::Weather::HourlyForecastEntry do
  let(:weather_condition) do
    Services::Domains::Weather::WeatherCondition.new(description: "Partly cloudy", type: "PARTLY_CLOUDY")
  end

  describe "#initialize" do
    it "sets required attributes" do
      entry = described_class.new(
        weather_condition: weather_condition,
        temperature_degrees: 25.3
      )

      expect(entry.weather_condition).to eq(weather_condition)
      expect(entry.temperature_degrees).to eq(25.3)
    end

    it "sets optional attributes when provided" do
      entry = described_class.new(
        display_date_time: "2025-01-28 19:00",
        is_daytime: true,
        weather_condition: weather_condition,
        temperature_degrees: 25.3,
        feels_like_degrees: 26.1
      )

      expect(entry.display_date_time).to eq("2025-01-28 19:00")
      expect(entry.is_daytime).to be true
      expect(entry.feels_like_degrees).to eq(26.1)
    end

    it "returns nil for omitted optional attributes" do
      entry = described_class.new(
        weather_condition: weather_condition,
        temperature_degrees: 20
      )

      expect(entry.display_date_time).to be_nil
      expect(entry.is_daytime).to be_nil
      expect(entry.feels_like_degrees).to be_nil
    end
  end

  describe "immutability" do
    it "is frozen" do
      entry = described_class.new(
        weather_condition: weather_condition,
        temperature_degrees: 25
      )

      expect(entry).to be_frozen
    end
  end
end
