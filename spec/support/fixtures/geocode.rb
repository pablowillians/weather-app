module Fixtures
  module Geocode
    def load_geocode_fixture(name)
      path = Rails.root.join("spec/fixtures/geocode/#{name}.json")
      JSON.parse(File.read(path))
    end
  end
end
