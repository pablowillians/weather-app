class WeatherController < ApplicationController
  def index
    @address = params[:address].to_s.strip
    return unless @address.present?

    @result = Services::Application::WeatherByAddress.new.call(@address)
  rescue StandardError => e
    @error = e.message
  end

  def search
    redirect_to root_path(address: params[:address])
  end
end
