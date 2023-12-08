#
# Cookbook:: osl-matrix
# Spec:: osl_element
#
# Copyright:: 2023, Oregon State University
#

require_relative '../../spec_helper'

describe 'osl_element' do
  platform 'almalinux', '8'
  step_into :osl_element

  context 'Create' do
    cached(:subject) { chef_run }

    recipe do
      osl_element 'chat.example.org'
    end

    it { is_expected.to create_directory('/opt/element') }

    it do
      is_expected.to create_template('/opt/element/config.json').with(
        source: 'element-config.json.erb'
      )
    end

    it { is_expected.to pull_docker_image('vectorim/element-web') }

    it do
      is_expected.to run_docker_container('element_webapp').with(
        repo: 'vectorim/element-web',
        exposed_ports: { '80' => '80' },
        volumes: ['/opt/element/config.json:/app/config.json']
      )
    end
  end
end
