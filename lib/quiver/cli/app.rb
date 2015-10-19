require 'thor'
require 'active_support'
require 'quiver/version'

require 'quiver/cli/generators/new_application'
require 'quiver/cli/generators/new_application_cli'

module Quiver
  module CLI
    class App < Thor
      package_name "Quiver"

      desc "server", "run a Quiver application"
      method_option :host, aliases: ['-h', '-b'], desc: 'host for the server to bind to (default 127.0.0.1)'
      method_option :port, aliases: '-p', desc: 'port to listen on'
      method_option :reloading_code, aliases: '-r', desc: 'reload code automatically', type: :boolean, default: true
      def server
        require 'quiver/cli/server'
        Quiver::CLI::Server.new(options).start
      end

      register(NewApplicationCli, "new", "new APP_NAME", "generates a new Quiver application")
    end
  end
end
