module OSLMatrix
  module Cookbook
    module Helpers

      # Generate a secret key. Mainly used when wanting a registration key
      def osl_matrix_genkey(len = 64)
        require 'securerandom'
        SecureRandom.base64(len)
      end
      
      # Get the name of the synapse docker container name, given the name of the synapse resource which creates it
      def osl_synapse_docker_name(strSynapseResource)
        # Get the resource, and return the name
        find_resource(:osl_synapse, strSynapseResource).name
      end
    end
  end
end

Chef::DSL::Recipe.include ::OSLMatrix::Cookbook::Helpers
Chef::Resource.include ::OSLMatrix::Cookbook::Helpers
