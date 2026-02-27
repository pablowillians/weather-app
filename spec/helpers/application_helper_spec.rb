require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  def build_condition(description: "Clear", type: "CLEAR", icon_base_uri: nil)
    Services::Domains::Weather::WeatherCondition.new(
      description: description,
      type: type,
      icon_base_uri: icon_base_uri
    )
  end

  def build_hourly_entry(display_date_time: "2025-06-15 14:00", temperature_degrees: 25.0)
    Services::Domains::Weather::HourlyForecastEntry.new(
      display_date_time: display_date_time,
      weather_condition: build_condition,
      temperature_degrees: temperature_degrees
    )
  end

  describe "#weather_condition_icon_tag" do
    it "renders an img tag when icon_base_uri is present" do
      condition = build_condition(icon_base_uri: "https://example.com/icons/sunny")
      tag = helper.weather_condition_icon_tag(condition, size: 32)

      expect(tag).to have_css("img[src='https://example.com/icons/sunny.png']")
      expect(tag).to have_css("img[alt='Clear']")
      expect(tag).to have_css("img[width='32']")
      expect(tag).to have_css("img[height='32']")
    end

    it "renders a text span when icon_base_uri is blank" do
      condition = build_condition(icon_base_uri: nil)
      tag = helper.weather_condition_icon_tag(condition)

      expect(tag).to have_css("span", text: "Clear")
    end

    it "applies custom css_class" do
      condition = build_condition(icon_base_uri: "https://example.com/icons/sunny")
      tag = helper.weather_condition_icon_tag(condition, css_class: "my-icon")

      expect(tag).to have_css("img.my-icon")
    end
  end

  describe "#weather_hourly_label" do
    it "returns 'Now' for index 0" do
      entry = build_hourly_entry
      expect(helper.weather_hourly_label(entry, 0)).to eq("Now")
    end

    it "returns '--' when display_date_time is blank" do
      entry = build_hourly_entry(display_date_time: nil)
      expect(helper.weather_hourly_label(entry, 1)).to eq("--")
    end

    it "returns the time part when display_date_time has date and time" do
      entry = build_hourly_entry(display_date_time: "2025-06-15 14:00")
      expect(helper.weather_hourly_label(entry, 1)).to eq("14:00")
    end

    it "returns the single part when display_date_time has no space" do
      entry = build_hourly_entry(display_date_time: "14:00")
      expect(helper.weather_hourly_label(entry, 1)).to eq("14:00")
    end
  end

  describe "#weather_temp_bar_style" do
    it "calculates left and right percentages" do
      style = helper.weather_temp_bar_style(10.0, 20.0, 0.0, 40.0)
      expect(style).to eq("left: 25%; right: 50%;")
    end

    it "returns 0%/0% when range is zero" do
      style = helper.weather_temp_bar_style(20.0, 20.0, 20.0, 20.0)
      expect(style).to eq("left: 0%; right: 0%;")
    end

    it "handles full range" do
      style = helper.weather_temp_bar_style(0.0, 40.0, 0.0, 40.0)
      expect(style).to eq("left: 0%; right: 0%;")
    end
  end

  describe "#weather_source_badge" do
    def build_result(source_value)
      weather_at_location = Services::Domains::Weather::WeatherAtLocation.new(
        location: Services::Domains::Geocode::Location.new(latitude: 0, longitude: 0),
        current_weather: Services::Domains::Weather::CurrentWeather.new(
          current_time: Time.now,
          time_zone_id: "UTC",
          is_daytime: true,
          weather_condition: build_condition,
          temperature_degrees: 20.0
        ),
        hourly_forecast_entries: [],
        daily_forecast_entries: []
      )

      Services::Application::WeatherByAddress::Result.new(
        weather_at_location: weather_at_location,
        sources: { current_weather: source_value }
      )
    end

    it "shows 'API' for api_response source" do
      result = build_result(:api_response)
      badge = helper.weather_source_badge(result, :current_weather)

      expect(badge).to have_text("API")
      expect(badge).to have_css(".bg-emerald-500\\/80")
    end

    it "shows 'Cache' for cached_response source" do
      result = build_result(:cached_response)
      badge = helper.weather_source_badge(result, :current_weather)

      expect(badge).to have_text("Cache")
      expect(badge).to have_css(".bg-zinc-500")
    end
  end
end
