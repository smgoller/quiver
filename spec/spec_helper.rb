$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
ENV['RACK_ENV'] = 'test'

require 'quiver'
require 'quiver/adapter/active_record_helpers'

require 'dummy/lib/pwny'
require 'rack/test'
require 'ffaker'
require 'factory_girl'
require 'database_cleaner'
require 'timecop'

FactoryGirl.find_definitions

load 'dummy/db/schema.rb'

RSpec.configure do |config|
  config.include Rack::Test::Methods

  def app
    Pwny::Application.new
  end

  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end

    Pwny::Application.memory_adapter_store.clean!
  end
end

require 'support/application_mock_helper'
