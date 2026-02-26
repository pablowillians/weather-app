module Services
  module Infrastructure
    module Adapters
      module Weather
        # ## Google Current Weather API response
        #
        # Response for the current conditions endpoint. Payload includes **currentTime**, **temperature**,
        # **weatherCondition**, **feelsLikeTemperature**, **relativeHumidity**, **wind**, **cloudCover**, etc.
        # Use **data** and **source** from the parent **GoogleWeatherResponse**.
        class GoogleCurrentWeatherResponse < GoogleWeatherResponse; end
      end
    end
  end
end
