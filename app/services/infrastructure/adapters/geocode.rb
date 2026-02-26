# frozen_string_literal: true

module Services
  module Infrastructure
    module Adapters
      # ## Geocode
      #
      # Namespace for geocoding adapters. Converts addresses or place names into
      # coordinates and optional postal data (e.g. zipcode).
      #
      # ### Contents
      #
      # - **GoogleGeocode** — Adapter for the [Google Geocode API](https://developers.google.com/maps/documentation/geocoding/start).
      #   Use #call with an address string; returns a **GoogleGeocodeResponse**.
      # - **GoogleGeocodeResponse** — Wraps the API response: **latitude**, **longitude**, **zipcode**, **source**.
      # - **Error** — Base exception when the request fails.
      # - **NotFoundError** — Raised when no results are found for the given address.
      module Geocode
      end
    end
  end
end
