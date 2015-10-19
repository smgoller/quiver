require 'spec_helper'

describe 'Logging' do
  context 'ponies#index' do
    it 'has an extra logging field' do
      expect(Pwny::Application.logger).to receive(:info) do |log_hash|
        expect(log_hash[:test]).to eq('an extra field!')
      end

      Pwny::Endpoints::Ponies::Index.new.call({})
    end
  end
end
