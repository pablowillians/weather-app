# ## WeatherController
#
# Single-resource controller that powers the weather search page.
#
# ### Routes
#
#   GET  /                 → #index   (root)
#   GET  /weather/search   → #search  → redirects to root with address param
#
# ### Flow
#
# 1. User lands on the root page (empty search).
# 2. Submitting the search form hits <tt>#search</tt>, which redirects back
#    to root with the +address+ query parameter.
# 3. <tt>#index</tt> detects the address, calls
#    {Services::Application::WeatherByAddress} to geocode and fetch weather,
#    and assigns +@result+ for the view.
# 4. On error, +@error+ is set and shown in the +_error+ partial.
class WeatherController < ApplicationController
  # Renders the main weather page.
  #
  # When +params[:address]+ is present, delegates to
  # {Services::Application::WeatherByAddress} and assigns:
  #
  # - +@result+ — a {Services::Application::WeatherByAddress::Result}
  #   with location, current weather, hourly and daily forecasts.
  # - +@error+ — error message string if the service raises.
  # - +@address+ — the raw search string (always set).
  def index
    @address = params[:address].to_s.strip
    return unless @address.present?

    @result = Services::Application::WeatherByAddress.new.call(@address)
  rescue StandardError => e
    @error = e.message
  end

  # Accepts the search form submission and redirects to +root_path+
  # with the address as a query parameter, keeping the URL bookmarkable.
  def search
    redirect_to root_path(address: params[:address])
  end
end
