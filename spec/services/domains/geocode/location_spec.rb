# frozen_string_literal: true

require "rails_helper"

RSpec.describe Services::Domains::Geocode::Location do
  describe "#initialize" do
    it "sets latitude and longitude" do
      location = described_class.new(latitude: -23.55, longitude: -46.63)

      expect(location.latitude).to eq(-23.55)
      expect(location.longitude).to eq(-46.63)
      expect(location.zipcode).to be_nil
    end

    it "coerces latitude and longitude to Float" do
      location = described_class.new(latitude: "12.5", longitude: "34.0")

      expect(location.latitude).to eq(12.5)
      expect(location.longitude).to eq(34.0)
    end

    it "raises ArgumentError for non-numeric latitude" do
      expect { described_class.new(latitude: "abc", longitude: 0) }.to raise_error(ArgumentError)
    end

    it "raises ArgumentError for non-numeric longitude" do
      expect { described_class.new(latitude: 0, longitude: "abc") }.to raise_error(ArgumentError)
    end

    context "with zipcode" do
      it "sets zipcode" do
        location = described_class.new(latitude: 0, longitude: 0, zipcode: "01310-100")

        expect(location.zipcode).to eq("01310-100")
      end

      it "coerces zipcode to string" do
        location = described_class.new(latitude: 0, longitude: 0, zipcode: 12345)

        expect(location.zipcode).to eq("12345")
      end

      it "returns nil when zipcode is blank string" do
        location = described_class.new(latitude: 0, longitude: 0, zipcode: "   ")

        expect(location.zipcode).to be_nil
      end
    end

    context "with formatted_address" do
      it "sets formatted_address" do
        location = described_class.new(latitude: 0, longitude: 0, formatted_address: "Av. Paulista, São Paulo")

        expect(location.formatted_address).to eq("Av. Paulista, São Paulo")
      end

      it "returns nil when formatted_address is blank" do
        location = described_class.new(latitude: 0, longitude: 0, formatted_address: "  ")

        expect(location.formatted_address).to be_nil
      end

      it "returns nil when formatted_address is omitted" do
        location = described_class.new(latitude: 0, longitude: 0)

        expect(location.formatted_address).to be_nil
      end
    end
  end

  describe "immutability" do
    it "is frozen" do
      location = described_class.new(latitude: 0, longitude: 0)

      expect(location).to be_frozen
    end
  end
end
