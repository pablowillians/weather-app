require "rails_helper"

RSpec.describe Services::Infrastructure::Adapters::Weather::GoogleDailyForecast do
  let(:cache) { instance_double(ActiveSupport::Cache::Store) }
  let(:latitude) { -23.5557714 }
  let(:longitude) { -46.6395571 }

  before do
    allow(Rails).to receive(:cache).and_return(cache)
    allow(cache).to receive(:read)
    allow(cache).to receive(:write)
  end

  describe "#call" do
    context "when zipcode is provided" do
      let(:zipcode) { "01310-100" }
      let(:cache_key) { "google_daily_forecast_#{zipcode}" }

      context "when the response is cached" do
        let(:cached_data) { load_weather_fixture("daily_forecast_success") }

        before do
          allow(cache).to receive(:read).with(cache_key).and_return(cached_data)
        end

        it "returns a GoogleDailyForecastResponse with :cached_response source" do
          result = described_class.new.call(latitude, longitude, zipcode: zipcode)

          expect(result).to be_a(Services::Infrastructure::Adapters::Weather::GoogleDailyForecastResponse)
          expect(result.source).to eq(:cached_response)
          expect(result.data).to eq(cached_data)
        end

        it "does not make an HTTP request" do
          expect(Net::HTTP).not_to receive(:get_response)

          described_class.new.call(latitude, longitude, zipcode: zipcode)
        end
      end

      context "when the API returns a successful response" do
        let(:success_data) { load_weather_fixture("daily_forecast_success") }
        let(:http_response) { instance_double(Net::HTTPSuccess, body: success_data.to_json) }

        before do
          allow(cache).to receive(:read).with(cache_key).and_return(nil)
          allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(Net::HTTP).to receive(:get_response).and_return(http_response)
        end

        it "caches using the zipcode key" do
          expect(cache).to receive(:write).with(cache_key, success_data, expires_in: 30.minutes)

          described_class.new.call(latitude, longitude, zipcode: zipcode)
        end
      end
    end

    context "when zipcode is not provided" do
      let(:cache_key) { "google_daily_forecast_#{latitude}_#{longitude}" }

      context "when the response is cached" do
        let(:cached_data) { load_weather_fixture("daily_forecast_success") }

        before do
          allow(cache).to receive(:read).with(cache_key).and_return(cached_data)
        end

        it "returns a GoogleDailyForecastResponse with :cached_response source" do
          result = described_class.new.call(latitude, longitude)

          expect(result).to be_a(Services::Infrastructure::Adapters::Weather::GoogleDailyForecastResponse)
          expect(result.source).to eq(:cached_response)
          expect(result.data).to eq(cached_data)
        end

        it "does not make an HTTP request" do
          expect(Net::HTTP).not_to receive(:get_response)

          described_class.new.call(latitude, longitude)
        end
      end

      context "when the API returns a successful response" do
        let(:success_data) { load_weather_fixture("daily_forecast_success") }
        let(:http_response) { instance_double(Net::HTTPSuccess, body: success_data.to_json) }

        before do
          allow(cache).to receive(:read).with(cache_key).and_return(nil)
          allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
          allow(Net::HTTP).to receive(:get_response).and_return(http_response)
        end

        it "returns a GoogleDailyForecastResponse with :api_response source" do
          result = described_class.new.call(latitude, longitude)

          expect(result).to be_a(Services::Infrastructure::Adapters::Weather::GoogleDailyForecastResponse)
          expect(result.source).to eq(:api_response)
          expect(result.data).to eq(success_data)
        end

        it "caches using the lat/lng key" do
          expect(cache).to receive(:write).with(cache_key, success_data, expires_in: 30.minutes)

          described_class.new.call(latitude, longitude)
        end
      end
    end

    context "when the API returns no forecast data" do
      let(:not_found_data) { load_weather_fixture("daily_forecast_not_found") }
      let(:http_response) { instance_double(Net::HTTPSuccess, body: not_found_data.to_json) }

      before do
        allow(cache).to receive(:read).and_return(nil)
        allow(http_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
        allow(Net::HTTP).to receive(:get_response).and_return(http_response)
      end

      it "raises NotFoundError" do
        expect { described_class.new.call(latitude, longitude) }
          .to raise_error(
            Services::Infrastructure::Adapters::Weather::NotFoundError,
            "No daily forecast data found for coordinates: #{latitude}, #{longitude}"
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

      it "raises Error" do
        expect { described_class.new.call(latitude, longitude) }
          .to raise_error(
            Services::Infrastructure::Adapters::Weather::Error,
            "Failed to fetch daily forecast data"
          )
      end
    end
  end
end
