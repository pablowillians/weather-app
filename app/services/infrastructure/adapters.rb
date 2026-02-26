# frozen_string_literal: true

module Services
  module Infrastructure
    # ## Adapters
    #
    # Namespace for external API adapters used by the application.
    # Each submodule groups adapters by domain (geocoding, weather) and provider.
    #
    # ### Contents
    #
    # - **Geocode** — Geocoding: convert addresses to coordinates (e.g. Google Geocode API).
    # - **Weather** — Weather: current conditions and forecasts by coordinates (e.g. Google Weather API).
    module Adapters
    end
  end
end
