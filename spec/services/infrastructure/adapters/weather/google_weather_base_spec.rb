require "rails_helper"

RSpec.describe Services::Infrastructure::Adapters::Weather::GoogleWeatherBase do
  let(:cache) { instance_double(ActiveSupport::Cache::Store) }
  let(:latitude) { -23.5557714 }
  let(:longitude) { -46.6395571 }
  let(:success_data) { { "testData" => "present", "temperature" => 25.0 } }

  let(:test_adapter) do
    Class.new(described_class) do
      private

      def base_url = "https://weather.googleapis.com/v1/test:lookup"
      def cache_prefix = "google_test_weather"
      def response_class = Services::Infrastructure::Adapters::Weather::GoogleWeatherResponse
      def response_key = "testData"
      def error_label = "test weather"
    end
  end

  before do
    allow(Rails).to receive(:cache).and_return(cache)
    allow(cache).to receive(:read)
    allow(cache).to receive(:write)
  end

  describe "abstract contract" do
    it "raises NotImplementedError when subclass does not implement required methods" do
      bare_subclass = Class.new(described_class)

      allow(cache).to receive(:read).and_return(nil)

      expect { bare_subclass.new.call(latitude, longitude) }.to raise_error(NotImplementedError)
    end
  end

  describe "#call" do
    context "when zipcode is provided" do
      let(:zipcode) { "01310-100" }
      let(:cache_key) { "google_test_weather_#{zipcode}" }

      it "uses zipcode as cache key" do
        allow(cache).to receive(:read).with(cache_key).and_return(success_data)

        result = test_adapter.new.call(latitude, longitude, zipcode: zipcode)

        expect(result.source).to eq(:cached_response)
        expect(result.data).to eq(success_data)
      end
    end

    context "when zipcode is not provided" do
      let(:cache_key) { "google_test_weather_#{latitude}_#{longitude}" }

      it "uses lat/lng as cache key" do
        allow(cache).to receive(:read).with(cache_key).and_return(success_data)

        result = test_adapter.new.call(latitude, longitude)

        expect(result.source).to eq(:cached_response)
        expect(result.data).to eq(success_data)
      end
    end

    context "when the response is cached" do
      let(:cache_key) { "google_test_weather_#{latitude}_#{longitude}" }

      before do
        allow(cache).to receive(:read).with(cache_key).and_return(success_data)
      end

      it "returns a response with :cached_response source" do
        result = test_adapter.new.call(latitude, longitude)

        expect(result).to be_a(Services::Infrastructure::Adapters::Weather::GoogleWeatherResponse)
        expect(result.source).to eq(:cached_response)
      end

      it "does not make an HTTP request" do
        expect(Net::HTTP).not_to receive(:get_response)

        test_adapter.new.call(latitude, longitude)
      end
    end

    context "when the API returns a successful response" do
      let(:cache_key) { "google_test_weather_#{latitude}_#{longitude}" }
      let(:http_response) { instance_double(Net::HTTPSuccess, body: success_data.to_json) }

      before do
        allow(cache).to receive(:read).with(cache_key).and_return(nil)
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:get_response).and_return(http_response)
      end

      it "returns a response with :api_response source" do
        result = test_adapter.new.call(latitude, longitude)

        expect(result).to be_a(Services::Infrastructure::Adapters::Weather::GoogleWeatherResponse)
        expect(result.source).to eq(:api_response)
        expect(result.data).to eq(success_data)
      end

      it "writes to cache with 30 minutes expiration" do
        expect(cache).to receive(:write).with(cache_key, success_data, expires_in: 30.minutes)

        test_adapter.new.call(latitude, longitude)
      end
    end

    context "when the API returns no data for the response key" do
      let(:empty_data) { {} }
      let(:http_response) { instance_double(Net::HTTPSuccess, body: empty_data.to_json) }

      before do
        allow(cache).to receive(:read).and_return(nil)
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:get_response).and_return(http_response)
      end

      it "raises NotFoundError with the error_label in the message" do
        expect { test_adapter.new.call(latitude, longitude) }
          .to raise_error(
            Services::Infrastructure::Adapters::Weather::NotFoundError,
            "No test weather data found for coordinates: #{latitude}, #{longitude}"
          )
      end
    end

    context "when the API returns an HTTP error" do
      let(:http_response) { instance_double(Net::HTTPInternalServerError) }

      before do
        allow(cache).to receive(:read).and_return(nil)
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
        allow(Net::HTTP).to receive(:get_response).and_return(http_response)
      end

      it "raises Error with the error_label in the message" do
        expect { test_adapter.new.call(latitude, longitude) }
          .to raise_error(
            Services::Infrastructure::Adapters::Weather::Error,
            "Failed to fetch test weather data"
          )
      end
    end

    context "when subclass defines extra_params" do
      let(:adapter_with_params) do
        Class.new(described_class) do
          private

          def base_url = "https://weather.googleapis.com/v1/test:lookup"
          def cache_prefix = "google_test_weather"
          def response_class = Services::Infrastructure::Adapters::Weather::GoogleWeatherResponse
          def response_key = "testData"
          def error_label = "test weather"
          def extra_params = { hours: 12 }
        end
      end

      let(:http_response) { instance_double(Net::HTTPSuccess, body: success_data.to_json) }

      before do
        allow(cache).to receive(:read).and_return(nil)
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:get_response).and_return(http_response)
      end

      it "merges extra_params into the query string" do
        adapter_with_params.new.call(latitude, longitude)

        expect(Net::HTTP).to have_received(:get_response) do |uri|
          params = URI.decode_www_form(uri.query).to_h
          expect(params["hours"]).to eq("12")
        end
      end
    end
  end
end
