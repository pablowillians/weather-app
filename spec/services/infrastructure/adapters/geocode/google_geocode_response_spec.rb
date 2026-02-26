require "rails_helper"

RSpec.describe Services::Infrastructure::Adapters::Geocode::GoogleGeocodeResponse do
  describe "#initialize" do
    context "with valid arguments" do
      let(:data) { load_geocode_fixture("success") }
      let(:source) { :api_response }

      it "sets data and source" do
        response = described_class.new(data, source)

        expect(response.data).to eq(data)
        expect(response.source).to eq(:api_response)
      end
    end

    context "when data is nil" do
      it "raises ArgumentError" do
        expect { described_class.new(nil, :api_response) }
          .to raise_error(ArgumentError, "Data cannot be nil")
      end
    end

    context "when source is not a symbol" do
      let(:data) { load_geocode_fixture("success") }

      it "raises ArgumentError" do
        expect { described_class.new(data, "api_response") }
          .to raise_error(ArgumentError, "Source must be a symbol")
      end
    end
  end

  describe "#latitude" do
    it "returns the latitude from the first result" do
      response = described_class.new(load_geocode_fixture("success"), :api_response)

      expect(response.latitude).to eq(-23.5557714)
    end
  end

  describe "#longitude" do
    it "returns the longitude from the first result" do
      response = described_class.new(load_geocode_fixture("success"), :api_response)

      expect(response.longitude).to eq(-46.6395571)
    end
  end

  describe "#zipcode" do
    context "when postal_code is present" do
      it "returns the zipcode" do
        response = described_class.new(load_geocode_fixture("success_with_zipcode"), :api_response)

        expect(response.zipcode).to eq("01310-100")
      end
    end

    context "when postal_code is not present" do
      it "returns nil" do
        response = described_class.new(load_geocode_fixture("success"), :api_response)

        expect(response.zipcode).to be_nil
      end
    end
  end
end
