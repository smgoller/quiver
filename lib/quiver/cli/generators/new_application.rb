module Quiver
  module CLI
    class NewApplication
      include Thor::Base
      include Thor::Actions

      def self.source_root
        File.expand_path(File.join('..', '..', 'templates'), __FILE__)
      end

      def self.inherited(subclass)
        generators_hash.each do |k, v|
          subclass.generators_hash[k] = v
        end

        generators_array.each do |i|
          subclass.generators_array << i
        end
      end

      def self.generators_array
        @generators_array ||= []
      end

      def self.generators_hash
        @generators_hash ||= {}
      end

      def self.register_step(name, step, opts={})
        generators_hash[name] = step
        generators_array << name unless opts[:skip_queueing] || generators_array.include?(name)
      end

      def initialize(name, options)
        self.name = name
        self.options = options
        @destination_stack ||= []
        self.behavior = :invoke
      end

      def generate!
        self.class.generators_array.each do |name|
          if step = self.class.generators_hash[name]
            instance_exec(&step)
          end
        end

        git_init
      end

      register_step :gemfile, proc {
        template(
          File.join('Gemfile.tt'),
          File.join(underscored_name, 'Gemfile')
        )
      }

      register_step :gemspec, proc {
        template(
          File.join('gemspec.tt'),
          File.join(underscored_name, "#{underscored_name}.gemspec")
        )
      }

      register_step :rakefile, proc {
        template(
          File.join('Rakefile.tt'),
          File.join(underscored_name, 'Rakefile')
        )
      }

      register_step :config_ru, proc {
        template(
          File.join('config.tt'),
          File.join(underscored_name, 'config.ru')
        )
      }

      register_step :application, proc {
        template(
          File.join('lib', 'application.tt'),
          File.join(underscored_name, 'lib', "#{underscored_name}.rb")
        )
      }

      register_step :version, proc {
        template(
          File.join('lib', 'application', 'version.tt'),
          File.join(underscored_name, 'lib', underscored_name, 'version.rb')
        )
      }

      register_step :router, proc {
        template(
          File.join('lib', 'application', 'config', 'router.tt'),
          File.join(underscored_name, 'lib', underscored_name, 'config', 'router.rb')
        )
      }

      register_step :gitkeeps, proc {
        create_file(File.join(underscored_name, 'config', '.gitkeep'))
        create_file(File.join(underscored_name, 'lib', underscored_name, 'adapters', '.gitkeep'))
        create_file(File.join(underscored_name, 'lib', underscored_name, 'endpoints', '.gitkeep'))
        create_file(File.join(underscored_name, 'lib', underscored_name, 'mappers', '.gitkeep'))
        create_file(File.join(underscored_name, 'lib', underscored_name, 'models', '.gitkeep'))
        create_file(File.join(underscored_name, 'lib', underscored_name, 'serializers', '.gitkeep'))
      }

      register_step :gitignore, proc {
        template(
          File.join('gitignore.tt'),
          File.join(underscored_name, '.gitignore')
        )
      }

      register_step :spec_helper, proc {
        if options[:rspec]
          template(
            File.join('spec', 'spec_helper.tt'),
            File.join(underscored_name, 'spec', 'spec_helper.rb')
          )

          create_file(File.join(underscored_name, 'spec', 'support', '.gitkeep'))
        end
      }

      register_step :active_record, proc {
        if options[:active_record]
          create_file(File.join(underscored_name, 'db', 'migrate', '.gitkeep'))

          template(
            File.join('config', 'database.tt'),
            File.join(underscored_name, 'config', 'database.yml')
          )

          template(
            File.join('config', 'database.tt'),
            File.join(underscored_name, 'config', 'database.example.yml')
          )
        end
      }

      private

      attr_accessor :name, :options

      def underscored_name
        @underscored_name ||= name.underscore
      end

      def camelized_name
        @camelized_name ||= name.camelize
      end

      def git_init
        inside(underscored_name) do
          run('git init')
          run('git add .')

          output = run(%Q{git commit -m " Initial Commit\n _____________________\n|                    /--<<<\n|___________________/----<<<"}, verbose: false, capture: true)
          puts output.sub(/Commit.*?\n/, "Commit\n")
        end
      end
    end
  end
end
