require "rails_helper"

RSpec.describe "Root page", type: :request do
  it "returns 200" do
    get "/"
    expect(response).to have_http_status(:ok)
  end
end
