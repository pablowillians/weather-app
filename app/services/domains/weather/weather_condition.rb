# frozen_string_literal: true

module Services
  module Domains
    module Weather
      # Value object: weather condition description, API type code, and optional icon URI.
      # +description+ and +type+ are coerced to frozen strings; blank +icon_base_uri+ becomes +nil+.
      class WeatherCondition
        attr_reader :description, :type, :icon_base_uri

        def initialize(description:, type:, icon_base_uri: nil)
          @description = description.to_s.freeze
          @type = type.to_s.freeze
          @icon_base_uri = icon_base_uri.to_s.presence
          freeze
        end
      end
    end
  end
end
