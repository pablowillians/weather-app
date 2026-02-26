require "rails_helper"

RSpec.describe Services::Infrastructure::Adapters::Weather::GoogleCurrentWeatherResponse do
  describe "#initialize" do
    context "with valid arguments" do
      let(:data) { load_weather_fixture("current_weather_success") }
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
      let(:data) { load_weather_fixture("current_weather_success") }

      it "raises ArgumentError" do
        expect { described_class.new(data, "api_response") }
          .to raise_error(ArgumentError, "Source must be a symbol")
      end
    end
  end
end
