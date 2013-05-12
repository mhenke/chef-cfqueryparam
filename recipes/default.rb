#
# Cookbook Name:: qpscanner
# Recipe:: default
#
# Copyright 2013, Mike Henke
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
#

# Install the unzip package
package "unzip" do
  action :install
end

file_name = node['qpscanner']['download']['url'].split('/').last

node.set['qpscanner']['owner'] = node['cf10']['installer']['runtimeuser'] if node['qpscanner']['owner'] == nil

# Download qpscanner
remote_file "#{Chef::Config['file_cache_path']}/#{file_name}" do
  source "#{node['qpscanner']['download']['url']}"
  action :create_if_missing
  mode "0744"
  owner "root"
  group "root"
  not_if { File.directory?("#{node['qpscanner']['install_path']}/qpscanner") }
end

# Create the target install directory if it doesn't exist
directory "#{node['qpscanner']['install_path']}" do
  owner node['qpscanner']['owner']
  group node['qpscanner']['group']
  mode "0755"
  recursive true
  action :create
  not_if { File.directory?("#{node['qpscanner']['install_path']}") }
end

# Extract archive
script "install_qpscanner" do
  interpreter "bash"
  user "root"
  cwd "#{Chef::Config['file_cache_path']}"
  code <<-EOH
unzip #{file_name}
mv qpscanner-master #{node['qpscanner']['install_path']}/qpscanner
chown -R #{node['qpscanner']['owner']}:#{node['qpscanner']['group']} #{node['qpscanner']['install_path']}/qpscanner
rm  #{file_name}
EOH
  not_if { File.directory?("#{node['qpscanner']['install_path']}/qpscanner") }
end

# Set up ColdFusion mapping
execute "start_cf_for_qpscanner_default_cf_config" do
  command "/bin/true"
  notifies :start, "service[coldfusion]", :immediately
end

coldfusion10_config "extensions" do
  action :set
  property "mapping"
  args ({ "mapName" => "/qpscanner",
          "mapPath" => "#{node['qpscanner']['install_path']}/qpscanner"})
end

# Create a global apache alias if desired
template "#{node['apache']['dir']}/conf.d/global-qpscanner-alias" do
  source "global-qpscanner-alias.erb"
  owner node['apache']['user']
  group node['apache']['group']
  mode "0755"
  variables(
    :url_path => '/qpscanner',
    :file_path => "#{node['qpscanner']['install_path']}/qpscanner"
  )
  only_if { node['qpscanner']['create_apache_alias'] }
  notifies :restart, "service[apache2]"
end