#
# Cookbook:: osl-matrix
# Spec:: osl_element
#
# Copyright:: 2023-2025, Oregon State University
#

require_relative '../../spec_helper'

describe 'osl-matrix-test::element' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge({ step_into: :osl_element })).converge(described_recipe)
      end

      it { is_expected.to create_directory('/opt/element') }
      it { is_expected.to create_template('/opt/element/config.json').with(source: 'element-config.json.erb') }

      it do
        expect(chef_run.template('/opt/element/config.json')).to \
          notify('docker_container[element_webapp]').to(:redeploy)
      end

      it { is_expected.to pull_docker_image('vectorim/element-web').with(tag: 'latest') }

      it do
        expect(chef_run.docker_image('vectorim/element-web')).to \
          notify('docker_container[element_webapp]').to(:redeploy).immediately
      end

      it do
        is_expected.to run_docker_container('element_webapp').with(
          repo: 'vectorim/element-web',
          port: ['8000:80']
        )
      end
    end
  end
end
