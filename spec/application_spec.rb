require 'spec_helper'

describe Quiver::Application do
  module TestAppModule
    class Application
      include Quiver::Application
    end
  end

  describe 'auto detection of paths and module' do
    it 'has the correct app_root' do
      expect(TestAppModule::Application.app_root).to eq(File.expand_path('..', __dir__))
    end

    it 'has the correct lib_dir' do
      expect(TestAppModule::Application.lib_dir).to eq(File.expand_path('../lib/application_spec', __dir__))
    end

    it 'has the correct root_module' do
      expect(TestAppModule::Application.root_module).to eq(TestAppModule)
    end
  end

  describe 'load_everything!' do
    it 'loads everything' do
      expect(TestAppModule::Application).to receive(:require).with(
        File.expand_path('../lib/application_spec/config/router', __dir__)
      )

      TestAppModule::Application.load_everything!
    end
  end

  describe 'Endpoints module' do
    it 'is automatically defined on the parent module by including Quiver::Application' do
      expect(TestAppModule::Endpoints).to be_truthy
    end
  end
end
