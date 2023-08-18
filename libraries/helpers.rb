module OSLMatrix
  module Cookbook
    module Helpers

      # Create the synapse user, and the recommended directories
      def init_environment()
        user 'synapse-host' do
          system true
        end

        # Synapse configuration
        directory '/srv/synapse' do
          owner 'synapse-host'
          mode '750'
        end

        # Keys directory
        directory '/srv/synapse/keys' do
          owner 'synapse-host'
          mode '700'
        end
      end

    end
  end
end

Chef::DSL::Recipe.include ::OSLMatrix::Cookbook::Helpers
Chef::Resource.include ::OSLMatrix::Cookbook::Helpers
