require "rails_helper"

RSpec.describe Services::Infrastructure::Adapters::Weather::GoogleWeatherResponse do
  describe "#initialize" do
    context "with valid arguments" do
      it "sets data and source" do
        response = described_class.new({ "temperature" => 25.0 }, :api_response)

        expect(response.data).to eq({ "temperature" => 25.0 })
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
      it "raises ArgumentError" do
        expect { described_class.new({}, "api_response") }
          .to raise_error(ArgumentError, "Source must be a symbol")
      end
    end
  end
end
