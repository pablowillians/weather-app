require "application_system_test_case"

class RootPageTest < ApplicationSystemTestCase
  test "visiting the root page shows coming soon" do
    visit root_url
    assert_selector "h1", text: "Coming Soon"
  end
end
