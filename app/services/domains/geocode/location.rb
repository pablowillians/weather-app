# frozen_string_literal: true

module Services
  module Domains
    module Geocode
      # Value object: geographic coordinates with optional zipcode and formatted address.
      # Coordinates are coerced with +Float()+; blank string optionals become +nil+.
      class Location
        attr_reader :latitude, :longitude, :zipcode, :formatted_address

        def initialize(latitude:, longitude:, zipcode: nil, formatted_address: nil)
          @latitude = Float(latitude)
          @longitude = Float(longitude)
          @zipcode = zipcode.to_s.presence
          @formatted_address = formatted_address.to_s.presence
          freeze
        end
      end
    end
  end
end
