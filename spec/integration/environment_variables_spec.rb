require 'spec_helper'

describe 'Environment Variable Defaults' do
  it 'can have defaults for environment variables' do
    expect(ENV['I_AM_ENV_VAR']).to eq("hear me roar!")
  end

  it 'can have variables nested under a rack environment' do
    expect(ENV['I_AM_ENV_VAR_TOO']).to eq("woopty do")
    expect(ENV['I_AM_THIRD']).to eq("testy doodles doodles doodles")
  end
end
