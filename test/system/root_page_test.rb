require "application_system_test_case"

class RootPageTest < ApplicationSystemTestCase
  test "displays the app header with link to root" do
    visit root_url
    assert_selector "header a", text: "Weather App"
  end

  test "displays the search input" do
    visit root_url
    assert_selector "input[name='address']"
    assert_selector "input[placeholder*='Search address']"
  end

  test "search input has autofocus" do
    visit root_url
    assert_selector "input[name='address'][autofocus]"
  end

  test "does not display weather results without a search" do
    visit root_url
    assert_no_text "Feels like"
    assert_no_selector "span", text: "schedule", exact_text: true
    assert_no_selector "span", text: "calendar_month", exact_text: true
  end

  test "submitting the search form navigates with address param" do
    with_stubbed_service(raise_error: Services::Application::AddressNotFoundError.new("not found")) do
      visit root_url
      fill_in "address", with: "test-address-query"
      find("input[name='address']").native.send_keys(:return)

      assert_current_path root_path(address: "test-address-query")
    end
  end

  test "preserves the address value after search" do
    with_stubbed_service(raise_error: Services::Application::AddressNotFoundError.new("not found")) do
      visit root_url(address: "some place")
      assert_field "address", with: "some place"
    end
  end

  test "displays error message when address is not found" do
    with_stubbed_service(raise_error: Services::Application::AddressNotFoundError.new("No results found for this address")) do
      visit root_url(address: "nonexistent-place-xyz")
      assert_text "No results found for this address"
    end
  end

  test "displays weather results for a valid address" do
    with_stubbed_service(result: build_mock_result) do
      visit root_url(address: "New York")

      assert_text "New York, NY, USA"
      assert_text "25"
      assert_text "Partly Cloudy"
      assert_text "Feels like"
      assert_selector "span", text: "schedule", exact_text: true
      assert_selector "span", text: "calendar_month", exact_text: true
    end
  end

  private

  def with_stubbed_service(result: nil, raise_error: nil)
    original_new = Services::Application::WeatherByAddress.method(:new)

    Services::Application::WeatherByAddress.define_singleton_method(:new) do |**_args|
      fake = Object.new
      if raise_error
        fake.define_singleton_method(:call) { |_addr| raise raise_error }
      else
        fake.define_singleton_method(:call) { |_addr| result }
      end
      fake
    end

    yield
  ensure
    Services::Application::WeatherByAddress.define_singleton_method(:new, original_new)
  end

  def build_mock_result
    condition = Services::Domains::Weather::WeatherCondition.new(
      description: "Partly Cloudy", type: "PARTLY_CLOUDY"
    )
    location = Services::Domains::Geocode::Location.new(
      latitude: 40.71, longitude: -74.01,
      zipcode: "10001", formatted_address: "New York, NY, USA"
    )
    current = Services::Domains::Weather::CurrentWeather.new(
      current_time: Time.now, time_zone_id: "America/New_York",
      is_daytime: true, weather_condition: condition,
      temperature_degrees: 25.0, feels_like_degrees: 27.0
    )
    hourly = Array.new(6) do |i|
      Services::Domains::Weather::HourlyForecastEntry.new(
        display_date_time: "2025-06-15 #{14 + i}:00",
        weather_condition: condition,
        temperature_degrees: 24.0 + i
      )
    end
    daily = Array.new(5) do |i|
      Services::Domains::Weather::DailyForecastEntry.new(
        display_date: (Date.new(2025, 6, 15) + i).to_s,
        max_temperature_degrees: 30.0 + i,
        min_temperature_degrees: 18.0 - i,
        weather_condition: condition
      )
    end
    weather = Services::Domains::Weather::WeatherAtLocation.new(
      location: location, current_weather: current,
      hourly_forecast_entries: hourly, daily_forecast_entries: daily
    )

    Services::Application::WeatherByAddress::Result.new(
      weather_at_location: weather,
      sources: {
        geocode: :api_response, current_weather: :api_response,
        hourly_forecast: :api_response, daily_forecast: :api_response
      }
    )
  end
end
