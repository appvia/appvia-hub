require 'rails_helper'

RSpec.describe 'Home', type: :request do
  describe 'GET /healthz' do
    it 'returns a 204' do
      get '/healthz'
      expect(response).to have_http_status(204)
    end
  end
end
