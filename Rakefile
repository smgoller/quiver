require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :environment do
end

desc 'Drop, create and migrate the dummy app database'
task :generate_dummy_schema do
  ENV['BUNDLE_GEMFILE'] = File.absolute_path(ENV['BUNDLE_GEMFILE']) if ENV['BUNDLE_GEMFILE']
  cd 'spec/dummy' do
    sh 'rake db:drop db:create db:migrate'
  end
end
