require_relative '../../spec_helper'

describe 'osl-matrix::default' do
  platform 'almalinux', '8'
  cached(:subject) { chef_run }

  it 'converges successfully' do
    expect { chef_run }.to_not raise_error
  end
end
