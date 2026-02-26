# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Domains::Weather::WeatherCondition do
  describe "#initialize" do
    it "sets description and type" do
      condition = described_class.new(description: "Partly cloudy", type: "PARTLY_CLOUDY")

      expect(condition.description).to eq("Partly cloudy")
      expect(condition.type).to eq("PARTLY_CLOUDY")
      expect(condition.icon_base_uri).to be_nil
    end

    it "coerces description and type to string" do
      condition = described_class.new(description: :Sunny, type: :CLEAR)

      expect(condition.description).to eq("Sunny")
      expect(condition.type).to eq("CLEAR")
    end

    context "with icon_base_uri" do
      it "sets icon_base_uri" do
        uri = "https://maps.gstatic.com/weather/v1/partly_cloudy"
        condition = described_class.new(description: "Cloudy", type: "CLOUDY", icon_base_uri: uri)

        expect(condition.icon_base_uri).to eq(uri)
      end

      it "returns nil when icon_base_uri is blank" do
        condition = described_class.new(description: "Clear", type: "CLEAR", icon_base_uri: "  ")

        expect(condition.icon_base_uri).to be_nil
      end
    end
  end

  describe "immutability" do
    it "is frozen" do
      condition = described_class.new(description: "Rain", type: "RAIN")

      expect(condition).to be_frozen
    end
  end
end
