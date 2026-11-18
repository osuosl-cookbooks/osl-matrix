include_recipe 'osl-docker'

osl_synapse_admin 'test_admin' do
  home_server 'https://chat.example.org'
end

osl_synapse_admin 'test_multiple_servers' do
  home_server %w(https://chat.example.org https://ops.example.org https://osuosl.example.org)
  port 8081
end

osl_synapse_admin 'test_pinned' do
  home_server 'https://chat.example.org'
  port 8082
  tag 'v1.5.2'
  config('asManagedUsers' => ['^@bot:example.org$'])
end
