#
# Cookbook:: osl-matrix
# Spec:: osl_synapse_admin
#
# Copyright:: 2023-2026, Oregon State University
#

require_relative '../../spec_helper'

describe 'osl-matrix-test::synapse-admin' do
  ALL_PLATFORMS.each do |p|
    context "#{p[:platform]} #{p[:version]}" do
      cached(:chef_run) do
        ChefSpec::SoloRunner.new(p.merge({ step_into: :osl_synapse_admin })).converge(described_recipe)
      end

      include_context 'common'

      it { is_expected.to include_recipe 'osl-docker' }

      {
        'test_admin' => {
          tag: 'v1',
          port: '8080',
          content: '{"restrictBaseUrl":"https://chat.example.org"}',
        },
        'test_multiple_servers' => {
          tag: 'v1',
          port: '8081',
          content: '{"restrictBaseUrl":["https://chat.example.org","https://ops.example.org","https://osuosl.example.org"]}',
        },
        'test_pinned' => {
          tag: 'v1.5.2',
          port: '8082',
          content: '{"asManagedUsers":["^@bot:example.org$"],"restrictBaseUrl":"https://chat.example.org"}',
        },
      }.each do |name, want|
        it { is_expected.to create_directory("/opt/synapse_admin_#{name}") }

        it do
          is_expected.to create_file("/opt/synapse_admin_#{name}/config.json").with(content: want[:content])
        end

        it do
          expect(chef_run.file("/opt/synapse_admin_#{name}/config.json")).to \
            notify("docker_container[#{name}]").to(:redeploy)
        end

        it { is_expected.to pull_docker_image("ketesa_#{name}").with(repo: 'etkecc/ketesa', tag: want[:tag]) }

        it do
          expect(chef_run.docker_image("ketesa_#{name}")).to \
            notify("docker_container[#{name}]").to(:redeploy)
        end

        it do
          is_expected.to run_docker_container(name).with(
            repo: 'etkecc/ketesa',
            tag: want[:tag],
            port: ["#{want[:port]}:8080"],
            volumes_binds: ["/opt/synapse_admin_#{name}/config.json:/var/public/config.json:ro"]
          )
        end
      end
    end
  end
end
