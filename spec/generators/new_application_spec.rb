require 'spec_helper'

describe 'Generating a new application from templates' do
  class << File
    # Best method evar!
    def rejoin(*args)
      args.flat_map { |a| a.split('/') }
      join(args)
    end
  end

  before do
    FileUtils.rm_rf(File.rejoin('spec/tmp/minos_plus_plus'), secure: true)
    FileUtils.mkdir(File.rejoin('spec/tmp')) unless File.exist?(File.rejoin('spec/tmp'))
    FileUtils.chdir(File.rejoin('spec/tmp'))
  end

  after do
    FileUtils.chdir(File.rejoin('../..'))
  end

  let(:app) { MinosPlusPlus::Application.new }

  %w|MinosPlusPlus minos_plus_plus|.each do |name|
    it "generates and runs the new application '#{name}'" do
      %x|../../bin/quiver new #{name}|
      require 'tmp/minos_plus_plus/lib/minos_plus_plus'

      get '/'
      expect(last_response.body).to eq('MinosPlusPlus is now flying out of the Quiver!')
    end
  end
end
