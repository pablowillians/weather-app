# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Domains::Weather::CurrentWeather do
  let(:weather_condition) do
    Services::Domains::Weather::WeatherCondition.new(description: "Partly cloudy", type: "PARTLY_CLOUDY")
  end

  describe "#initialize" do
    it "sets required attributes" do
      current_time = Time.utc(2025, 1, 28, 22, 4, 12)
      weather = described_class.new(
        current_time: current_time,
        time_zone_id: "America/Sao_Paulo",
        is_daytime: true,
        weather_condition: weather_condition,
        temperature_degrees: 25.3
      )

      expect(weather.current_time).to eq(current_time)
      expect(weather.time_zone_id).to eq("America/Sao_Paulo")
      expect(weather.is_daytime).to be true
      expect(weather.weather_condition).to eq(weather_condition)
      expect(weather.temperature_degrees).to eq(25.3)
    end

    it "coerces time_zone_id to string" do
      weather = described_class.new(
        current_time: Time.now,
        time_zone_id: :"America/Sao_Paulo",
        is_daytime: false,
        weather_condition: weather_condition,
        temperature_degrees: 20
      )

      expect(weather.time_zone_id).to eq("America/Sao_Paulo")
    end

    context "with optional attributes" do
      it "sets feels_like_degrees" do
        weather = described_class.new(
          current_time: Time.now,
          time_zone_id: "UTC",
          is_daytime: true,
          weather_condition: weather_condition,
          temperature_degrees: 25.3,
          feels_like_degrees: 26.1
        )

        expect(weather.feels_like_degrees).to eq(26.1)
      end

      it "returns nil for omitted optional attributes" do
        weather = described_class.new(
          current_time: Time.now,
          time_zone_id: "UTC",
          is_daytime: true,
          weather_condition: weather_condition,
          temperature_degrees: 20
        )

        expect(weather.feels_like_degrees).to be_nil
      end
    end
  end

  describe "immutability" do
    it "is frozen" do
      weather = described_class.new(
        current_time: Time.now,
        time_zone_id: "UTC",
        is_daytime: true,
        weather_condition: weather_condition,
        temperature_degrees: 25
      )

      expect(weather).to be_frozen
    end
  end
end
