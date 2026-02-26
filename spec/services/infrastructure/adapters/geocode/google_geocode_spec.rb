require "rails_helper"

RSpec.describe Services::Infrastructure::Adapters::Geocode::GoogleGeocode do

  let(:cache) { instance_double(ActiveSupport::Cache::Store) }
  let(:address) { "São Paulo, Brazil" }
  let(:cache_key) { "google_geocode_#{address}" }

  before do
    allow(Rails).to receive(:cache).and_return(cache)
    allow(cache).to receive(:read)
    allow(cache).to receive(:write)
  end

  describe "#call" do
    context "when the response is cached" do
      let(:cached_data) { load_geocode_fixture("success") }

      before do
        allow(cache).to receive(:read).with(cache_key).and_return(cached_data)
      end

      it "returns a GeocodeResponse with :cached_response source" do
        result = described_class.new.call(address)

        expect(result).to be_a(Services::Infrastructure::Adapters::Geocode::GoogleGeocodeResponse)
        expect(result.source).to eq(:cached_response)
        expect(result.data).to eq(cached_data)
      end

      it "does not make an HTTP request" do
        expect(Net::HTTP).not_to receive(:get_response)

        described_class.new.call(address)
      end
    end

    context "when the API returns a successful response" do
      let(:success_data) { load_geocode_fixture("success") }
      let(:http_response) { instance_double(Net::HTTPSuccess, body: success_data.to_json) }

      before do
        allow(cache).to receive(:read).with(cache_key).and_return(nil)
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:get_response).and_return(http_response)
      end

      it "returns a GeocodeResponse with :api_response source" do
        result = described_class.new.call(address)

        expect(result).to be_a(Services::Infrastructure::Adapters::Geocode::GoogleGeocodeResponse)
        expect(result.source).to eq(:api_response)
        expect(result.data).to eq(success_data)
      end

      it "writes the response to the cache with 7 days expiration" do
        expect(cache).to receive(:write).with(cache_key, success_data, expires_in: 7.days)

        described_class.new.call(address)
      end
    end

    context "when the API returns ZERO_RESULTS" do
      let(:zero_results_data) { load_geocode_fixture("zero_results") }
      let(:http_response) { instance_double(Net::HTTPSuccess, body: zero_results_data.to_json) }

      before do
        allow(cache).to receive(:read).with(cache_key).and_return(nil)
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:get_response).and_return(http_response)
      end

      it "raises NotFoundError" do
        expect { described_class.new.call(address) }
          .to raise_error(
            Services::Infrastructure::Adapters::Geocode::NotFoundError,
            "No Google Geocode data found for address: #{address}"
          )
      end
    end

    context "when the API returns an HTTP error" do
      let(:http_response) { instance_double(Net::HTTPInternalServerError) }

      before do
        allow(cache).to receive(:read).with(cache_key).and_return(nil)
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(Net::HTTP).to receive(:get_response).and_return(http_response)
      end

      it "raises Error" do
        expect { described_class.new.call(address) }
          .to raise_error(
            Services::Infrastructure::Adapters::Geocode::Error,
            "Failed to fetch Google Geocode data"
          )
      end
    end
  end
end
