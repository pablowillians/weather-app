module Fixtures
  module Weather
    def load_weather_fixture(name)
      path = Rails.root.join("spec/fixtures/weather/#{name}.json")
      JSON.parse(File.read(path))
    end
  end
end
