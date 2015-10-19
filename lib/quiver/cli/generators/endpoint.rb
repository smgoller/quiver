module Quiver
  module CLI
    class Endpoint < Thor::Group
      include Thor::Actions

      argument :name

      def self.source_root
        File.expand_path(File.join('..', '..'), __FILE__)
      end

      def first
        puts name
      end
    end
  end
end
