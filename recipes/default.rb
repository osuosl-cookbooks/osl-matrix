#
# Cookbook:: osl-matrix
# Recipe:: default
#
# Copyright:: 2023, Oregon State University
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

include_recipe 'osl-docker'

# Synapse management user
user 'synapse-host' do
  system true
end

# Synapse configuration, used within the docker container as a volume
directory '/etc/synapse' do
  owner 'synapse-host'
  group 'synapse-host'
  mode '750'
end

cookbook_file '/etc/synapse/homeserver.yaml' do
  source 'homeserver.yaml'

  owner 'synapse-host'
  group 'synapse-host'
end

docker_container 'Matrix Synapse' do
  repo 'matrixdotorg/synapse'
  volumes ['/etc/synapse:/data']
  env ["UID=#{node['ect']['passwd']['synapse-host']['uid']}", "GID=#{node['ect']['passwd']['synapse-host']['gid']}"]
end
