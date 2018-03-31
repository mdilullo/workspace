#
# Cookbook Name:: monitor
# Recipe:: master
#
# Copyright 2013, Sean Porter Consulting
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

include_recipe "monitor::default"
include_recipe "sensu::client_service"

sensu_gem 'sensu-plugins-couchbase'

handler = node['sensu']['handler']

cfg = node.config["couchbase"]["admin"]
sensu_check "couchbase-bucket-quotas" do
  command "check-couchbase-bucket-quota.rb -u #{cfg['username']} -p '#{cfg['password']}'"
  handlers [handler]
  standalone true
  interval 30
  additional(:occurrences => 5, :ttl =>300)
end

# sensu_check "#{node.name}-bucket-replica" do
  # command "check-couchbase-bucket-replica.rb -u #{cfg['username']} -p '#{cfg['password']}'"
  # handlers [handler]
  # standalone true
  # interval 30
# end

servers = search(:node, "chef_environment:#{node.chef_environment} AND roles:couchbase2 AND NOT disabled:true").length

sensu_check "couchbase-cluster" do
  command "check-couchbase-cluster.rb -u #{cfg['username']} -p '#{cfg['password']}' -c #{servers}"
  handlers [handler]
  standalone true
  additional(:occurrences => 5, :ttl =>300)
  interval 30
end
