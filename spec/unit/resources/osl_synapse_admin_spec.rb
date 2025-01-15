#
# Cookbook:: osl-matrix
# Spec:: osl_element
#
# Copyright:: 2023-2025, Oregon State University
#

require_relative '../../spec_helper'

describe 'osl-matrix-test::synapse-admin' do
  cached(:subject) { chef_run }
  platform 'almalinux', '8'
  step_into :osl_synapse_admin

  it { is_expected.to create_directory('/opt/synapse_admin') }

  it do
    is_expected.to create_file('/opt/synapse_admin/config.json').with(
      content: '{"restrictBaseUrl":"chat.example.org"}'
    )
  end

  it { is_expected.to pull_docker_image('awesometechnologies/synapse-admin') }

  it do
    is_expected.to run_docker_container('synapse_admin_webapp').with(
      repo: 'awesometechnologies/synapse-admin',
      port: ['8080:80']
    )
  end
end
