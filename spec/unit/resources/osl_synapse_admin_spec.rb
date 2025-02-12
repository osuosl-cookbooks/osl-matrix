#
# Cookbook:: osl-matrix
# Spec:: osl_element
#
# Copyright:: 2023-2025, Oregon State University
#

require_relative '../../spec_helper'

describe 'osl-matrix-test::synapse-admin' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge({ step_into: :osl_synapse_admin })).converge(described_recipe)
      end

      # Single server
      it { is_expected.to create_directory('/opt/synapse_admin_test_admin') }

      it do
        is_expected.to create_file('/opt/synapse_admin_test_admin/config.json').with(
          content: '{"restrictBaseUrl":"https://chat.example.org"}'
        )
      end

      it { is_expected.to pull_docker_image('awesometechnologies/synapse-admin') }

      it do
        is_expected.to run_docker_container('test_admin').with(
          repo: 'awesometechnologies/synapse-admin',
          port: ['8080:80']
        )
      end

      # Multiple servers
      it { is_expected.to create_directory('/opt/synapse_admin_test_multiple_servers') }

      it do
        is_expected.to create_file('/opt/synapse_admin_test_multiple_servers/config.json').with(
          content: '{"restrictBaseUrl":["https://chat.example.org","https://ops.example.org","https://osuosl.example.org"]}'
        )
      end

      it { is_expected.to pull_docker_image('awesometechnologies/synapse-admin') }

      it do
        is_expected.to run_docker_container('test_multiple_servers').with(
          repo: 'awesometechnologies/synapse-admin',
          port: ['8081:80']
        )
      end
    end
  end
end
