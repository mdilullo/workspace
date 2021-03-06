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

include_recipe "sensu::rabbitmq"
include_recipe "sensu::redis"

include_recipe "monitor::_worker"

include_recipe "sensu::api_service"
include_recipe "uchiwa"

include_recipe "monitor::default"

add_iptables_rule('INPUT', '-s 192.168.0.0/16 -p tcp --dport 3000 -j ACCEPT')
add_iptables_rule('INPUT', '-s 192.168.0.0/16 -p tcp --dport 8000 -j ACCEPT')
add_iptables_rule('INPUT', '-s 192.168.0.0/16 -p tcp --dport 4567 -j ACCEPT')
add_iptables_rule('INPUT', '-s 192.168.0.0/16 -p tcp --dport 5672 -j ACCEPT')

sensu_gem 'sensu-plugins-rabbitmq' do
  version '1.2.0'
end

file '/etc/sensu/plugins/openduty.rb' do
  mode '0755'
end

sensu_handler 'openduty' do
  type "pipe"
  command "/etc/sensu/plugins/openduty.rb"
end 
