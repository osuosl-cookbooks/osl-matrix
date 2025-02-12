include_recipe 'osl-docker'

osl_synapse_admin 'test_admin' do
  home_server 'https://chat.example.org'
end

osl_synapse_admin 'test_multiple_servers' do
  home_server %w(https://chat.example.org https://ops.example.org https://osuosl.example.org)
  port 8081
end
