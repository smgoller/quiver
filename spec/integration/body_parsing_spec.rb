require 'spec_helper'

describe 'JSON Body Parser' do
  it 'returns a more graceful error' do
    post '/post', nil, {'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json', 'rack.input' => StringIO.new('{invalid json}')}
    expect(JSON.parse(last_response.body)['errors'].first['status']).to eq('400')
  end
end
