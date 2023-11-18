module OSLMatrix
  module Cookbook
    module Helpers
      # Generate a secret key through hashing a string. Mainly used when wanting a registration key
      # WARNING: Not recommended for an actual deployment, only done when no secret is given.
      def osl_matrix_genkey(strPlaintext)
        require 'digest'
        Digest::MD5.hexdigest(strPlaintext)
      end

      # Get the name of the synapse docker container name, given the name of the synapse resource which creates it
      def osl_synapse_docker_name(strSynapseResource)
        # Get the resource, and return the name
        find_resource(:osl_synapse, strSynapseResource).name
      end

      # Create an app service file for Matrix Synapse
      def osl_synapse_appservice(id, url, appservicekey, homeserverkey, service, namespace)
        template "#{new_resource.host_path}/#{new_resource.container_name}.yaml" do
          source 'appservice.erb'
          cookbook 'osl-matrix'
          mode '644'
          variables(
            id: id,
            url: url,
            matrix_rand_appservice: appservicekey,
            matrix_rand_homeserver: homeserverkey,
            service: service,
            namespaces: namespace
          )
          sensitive true
        end
      end
    end
  end
end
Chef::DSL::Recipe.include ::OSLMatrix::Cookbook::Helpers
Chef::Resource.include ::OSLMatrix::Cookbook::Helpers
