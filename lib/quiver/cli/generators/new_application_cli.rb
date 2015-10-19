module Quiver
  module CLI
    class NewApplicationCli < Thor::Group
      include Thor::Actions

      argument :name
      class_option :active_record, type: :boolean, desc: "use ActiveRecord"
      class_option :rspec, type: :boolean, default: true, desc: "use RSpec"
      class_option :ext, type: :string, desc: "use the specified extension"

      def create_base_app
        klass = if options[:ext]
          require "#{options[:ext]}/quiver_ext"
          options[:ext].classify.constantize::QuiverExt::NewApplication
        else
          NewApplication
        end

        instance = klass.new(name, options)
        instance.destination_root = destination_root
        instance.generate!
      end
    end
  end
end
