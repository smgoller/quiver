require 'spec_helper'

describe 'Routing' do
  describe '/hello_world' do
    it 'routes to the appropriate action and returns the expected body' do
      get '/hello_world'

      expect(last_response.body).to eq('Hello World, from Pwny')
    end
  end
end
