# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Domains::Weather::DailyForecastEntry do
  let(:condition) do
    Services::Domains::Weather::WeatherCondition.new(description: "Partly cloudy", type: "PARTLY_CLOUDY")
  end

  describe "#initialize" do
    it "sets all attributes" do
      entry = described_class.new(
        display_date: "2025-01-28",
        max_temperature_degrees: 28.5,
        min_temperature_degrees: 19.3,
        weather_condition: condition
      )

      expect(entry.display_date).to eq("2025-01-28")
      expect(entry.max_temperature_degrees).to eq(28.5)
      expect(entry.min_temperature_degrees).to eq(19.3)
      expect(entry.weather_condition).to eq(condition)
    end

    it "allows nil for omitted optional attributes" do
      entry = described_class.new(
        max_temperature_degrees: 30,
        min_temperature_degrees: 18,
        weather_condition: condition
      )

      expect(entry.display_date).to be_nil
    end

    it "is frozen" do
      entry = described_class.new(
        max_temperature_degrees: 28,
        min_temperature_degrees: 19,
        weather_condition: condition
      )

      expect(entry).to be_frozen
    end
  end
end
