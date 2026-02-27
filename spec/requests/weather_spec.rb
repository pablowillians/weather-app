require "rails_helper"

RSpec.describe "Weather", type: :request do
  def build_condition(description: "Clear", type: "CLEAR")
    Services::Domains::Weather::WeatherCondition.new(
      description: description, type: type
    )
  end

  def build_result(sources: {})
    location = Services::Domains::Geocode::Location.new(
      latitude: -23.55, longitude: -46.63,
      zipcode: "01000-000", formatted_address: "São Paulo, Brazil"
    )
    current = Services::Domains::Weather::CurrentWeather.new(
      current_time: Time.now, time_zone_id: "America/Sao_Paulo",
      is_daytime: true, weather_condition: build_condition,
      temperature_degrees: 25.3, feels_like_degrees: 27.0
    )
    hourly = [
      Services::Domains::Weather::HourlyForecastEntry.new(
        display_date_time: "2025-06-15 14:00",
        weather_condition: build_condition,
        temperature_degrees: 25.0
      )
    ]
    daily = [
      Services::Domains::Weather::DailyForecastEntry.new(
        display_date: "2025-06-15",
        max_temperature_degrees: 30.0,
        min_temperature_degrees: 18.0,
        weather_condition: build_condition
      )
    ]
    weather = Services::Domains::Weather::WeatherAtLocation.new(
      location: location, current_weather: current,
      hourly_forecast_entries: hourly, daily_forecast_entries: daily
    )

    default_sources = {
      geocode: :api_response, current_weather: :api_response,
      hourly_forecast: :api_response, daily_forecast: :api_response
    }.merge(sources)

    Services::Application::WeatherByAddress::Result.new(
      weather_at_location: weather, sources: default_sources
    )
  end

  describe "GET /" do
    it "renders the index page" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the search form" do
      get root_path
      expect(response.body).to include("Search address or zip code")
    end

    it "renders the header" do
      get root_path
      expect(response.body).to include("Weather App")
    end

    context "without address" do
      it "does not call the weather service" do
        expect(Services::Application::WeatherByAddress).not_to receive(:new)
        get root_path
      end

      it "does not display weather results" do
        get root_path
        expect(response.body).not_to include("Feels like")
      end
    end

    context "with a valid address" do
      before do
        service = instance_double(Services::Application::WeatherByAddress)
        allow(Services::Application::WeatherByAddress).to receive(:new).and_return(service)
        allow(service).to receive(:call).with("São Paulo").and_return(build_result)
      end

      it "displays the location" do
        get root_path, params: { address: "São Paulo" }
        expect(response.body).to include("São Paulo, Brazil")
      end

      it "displays the current temperature" do
        get root_path, params: { address: "São Paulo" }
        expect(response.body).to include("25")
      end

      it "displays the weather condition" do
        get root_path, params: { address: "São Paulo" }
        expect(response.body).to include("Clear")
      end

      it "displays feels-like temperature" do
        get root_path, params: { address: "São Paulo" }
        expect(response.body).to include("Feels like")
        expect(response.body).to include("27")
      end

      it "displays hourly forecast" do
        get root_path, params: { address: "São Paulo" }
        expect(response.body).to include("Hourly Forecast")
      end

      it "displays daily forecast" do
        get root_path, params: { address: "São Paulo" }
        expect(response.body).to include("Daily Forecast")
      end

      it "displays location details" do
        get root_path, params: { address: "São Paulo" }
        expect(response.body).to include("-23.55")
        expect(response.body).to include("-46.63")
        expect(response.body).to include("America/Sao_Paulo")
      end

      it "preserves the address in the search field" do
        get root_path, params: { address: "São Paulo" }
        expect(response.body).to include("São Paulo")
      end
    end

    context "with whitespace-only address" do
      it "does not call the weather service" do
        expect(Services::Application::WeatherByAddress).not_to receive(:new)
        get root_path, params: { address: "   " }
      end
    end

    context "when address is not found" do
      before do
        service = instance_double(Services::Application::WeatherByAddress)
        allow(Services::Application::WeatherByAddress).to receive(:new).and_return(service)
        allow(service).to receive(:call)
          .and_raise(Services::Application::AddressNotFoundError, "Address not found")
      end

      it "displays the geocode error" do
        get root_path, params: { address: "nonexistent" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Address not found")
      end

      it "does not display weather results" do
        get root_path, params: { address: "nonexistent" }
        expect(response.body).not_to include("Feels like")
      end
    end

    context "when weather is not found" do
      before do
        service = instance_double(Services::Application::WeatherByAddress)
        allow(Services::Application::WeatherByAddress).to receive(:new).and_return(service)
        allow(service).to receive(:call)
          .and_raise(Services::Application::WeatherNotFoundError, "Weather data unavailable")
      end

      it "displays the weather error" do
        get root_path, params: { address: "somewhere" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Weather data unavailable")
      end
    end

    context "when a service error occurs" do
      before do
        service = instance_double(Services::Application::WeatherByAddress)
        allow(Services::Application::WeatherByAddress).to receive(:new).and_return(service)
        allow(service).to receive(:call)
          .and_raise(Services::Application::ServiceError, "Service unavailable")
      end

      it "displays the generic error" do
        get root_path, params: { address: "somewhere" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Service unavailable")
      end
    end
  end

  describe "GET /weather/search" do
    it "redirects to root with the address param" do
      get weather_search_path, params: { address: "New York" }
      expect(response).to redirect_to(root_path(address: "New York"))
    end

    it "redirects to root even without address" do
      get weather_search_path
      expect(response).to redirect_to(root_path(address: nil))
    end
  end
end
