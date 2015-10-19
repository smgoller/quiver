ENV['RACK_ENV'] ||= 'development'

require 'quiver/version'
require 'pry'
require 'active_support/all'

require 'lotus/router'
require 'lotus/controller'

Lotus::Controller.configure do
  format json_api: 'application/vnd.api+json'
  handle_exceptions false
end

require 'quiver/logger'

module Quiver
  def self.controller(s)
    Lotus::Controller.duplicate(s)
  end
end

require 'quiver/tasks'
require 'quiver/json_parser'
require 'quiver/router'
require 'quiver/adapter/memory_adapter_store'
require 'quiver/application'
require 'quiver/error'
require 'quiver/error_collection'
require 'quiver/validator'
require 'quiver/model'
require 'quiver/result'
require 'quiver/mapper'
require 'quiver/mappers'
require 'quiver/adapter'
require 'quiver/duty'
require 'quiver/duty_master'
require 'quiver/duty_test_helper'
require 'quiver/middleware_stack'

require 'quiver/abstract_action'
require 'quiver/action'
require 'quiver/patcher'
require 'quiver/serialization'

require 'quiver/cli/app'
