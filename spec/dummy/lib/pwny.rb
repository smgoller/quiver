require 'bundler/setup'
require 'quiver'

module Pwny
  class Application
    include Quiver::Application

    use_active_record!
    use_delayed_job!

    load_everything!
  end
end
