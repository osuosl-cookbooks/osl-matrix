#
# Cookbook:: osl-matrix
# Spec:: osl_element
#
# Copyright:: 2023, Oregon State University
#

require_relative '../../spec_helper'

describe 'create_element_site' do
  platform 'almalinux'
  step_into :osl_element

  recipe do
    osl_element 'chat.example.org'
  end

  it { is_expected.to include_recipe('osl-nginx') }

  describe run_docker_container('Element Webapp') do
    its('repo') { should eq 'vectorim/element-web' }
    its('exposed_ports') { should eq({ '80' => '80' }) }
  end

  describe create_nginx_app('Element Frontend') do
    its('cookbook') { should eq 'osl-matrix' }
  end
end
