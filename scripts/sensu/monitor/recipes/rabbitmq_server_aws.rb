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

sensu_gem "carrot-top"

sensu_gem 'sensu-plugins-rabbitmq' do
  version '1.2.0'
end

handler = "default"
#handler = node['sensu']['handler']

cookbook_file "/etc/sensu/plugins/check-rabbit-queue-redelivery.rb" do
  source "plugins/check-rabbit-queue-redelivery.rb"
  mode 0755
end

client_envs = search(:environment, "infrastructure:#{node.chef_environment}")
client_envs.each do |client_env|
  current = client_env.default_attributes["active"]
  cfg = client_env.default_attributes[current]["rabbit"]
  sensu_check "#{node.name}-#{cfg['virtual_host']}-alive" do
    command "check-rabbitmq-amqp-alive.rb -w #{node.ipaddress} -u #{cfg['username']} -v #{cfg['virtual_host']} -p '#{cfg['password']}'"
    handlers [handler]
    standalone true
    interval 30
    timeout 10
    additional(:occurrences => 5, :ttl =>200)
  end
  sensu_check "#{node.name}-#{cfg['virtual_host']}-queue" do
      command "metrics-rabbitmq-queue.rb --host #{node.ipaddress} --user #{cfg['username']} --vhost #{cfg['virtual_host']} --password '#{cfg['password']}' --scheme #{node.name}.rabbitmq.virtual_host.#{cfg['virtual_host']}"
    type "metric"
    handlers ["graphite"]
    standalone true
    interval 30
    timeout 10
    additional(:occurrences => 5, :ttl =>200)
  end
end

cfg = node.config["rabbit"]["admin"]
sensu_check "#{node.name}-partition" do
  command "check-rabbitmq-network-partitions.rb -w #{node.ipaddress} -u #{cfg['username']} -p '#{cfg['password']}'"
  handlers [handler]
  standalone true
  interval 30
  timeout 10
  additional(:occurrences => 5, :ttl =>200)
end
sensu_check "#{node.name}-health" do
  command "check-rabbitmq-node-health.rb -h #{node.ipaddress} -u #{cfg['username']} -p '#{cfg['password']}'"
  handlers [handler]
  standalone true
  interval 30
  timeout 10
  additional(:occurrences => 5, :ttl =>200)
end

sensu_check "#{node.name}-cluster-health" do
  command "check-rabbitmq-cluster-health.rb -h #{node.ipaddress} -u #{cfg['username']} -p '#{cfg['password']}'"
  handlers [handler]
  standalone true
  interval 30
  timeout 10
  additional(:occurrences => 5, :ttl =>200)
end

sensu_check "#{node.name}-messages" do
  command "check-rabbitmq-messages.rb --host #{node.ipaddress} --user #{cfg['username']} --password '#{cfg['password']}' -w 500 -c 2000"
  handlers [handler]
  standalone true
  interval 60
  timeout 10
  additional(:occurrences => 10, :ttl =>200)
end


sensu_check "#{node.name}-redeliveries" do
  command "check-rabbit-queue-redelivery.rb --host #{node.ipaddress} --user #{cfg['username']} --password '#{cfg['password']}' --warn 10 --crit 100"
  handlers [handler]
  standalone true
  interval 30
  timeout 10
  additional(:occurrences => 5, :ttl =>200)
end

sensu_check "#{node.name}-overview" do
    command "metrics-rabbitmq-overview.rb --host #{node.ipaddress} --user #{cfg['username']} --password '#{cfg['password']}' --scheme :::name:::.rabbitmq"
    type "metric"
    handlers ["graphite"]
    standalone true
    interval 30
    timeout 10
    additional(:occurrences => 5, :ttl =>200)
end
