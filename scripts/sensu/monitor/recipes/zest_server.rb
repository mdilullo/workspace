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

node.override['build-essential']['compile_time']=true

include_recipe 'build-essential'

include_recipe "monitor::default"

include_recipe "sensu::client_service"

sensu_gem 'sensu-plugins-ntp'

handler = "default"
#handler = node['sensu']['handler']

sensu_check "ntp" do
  command "check-ntp.rb -w 100 -c 300"
  handlers [handler]
  standalone true
  low_flap_threshold 20
  high_flap_threshold 60   
  interval 30
  timeout 15
  additional(:notification => "Ntp client is not running", :occurrences => 5, :ttl =>150)
end

sensu_gem 'sensu-plugins-disk-checks'

sensu_check "disks_usage" do
  command "check-disk-usage.rb -w 80% -c 85% -p /run/lxcfs -x tracefs,tmpfs,overlay,nsfs"
  handlers [handler]
  standalone true
  interval 60
  timeout 30
  additional(:occurrences => 5, :ttl =>600)
end

sensu_gem 'sensu-plugins-memory-checks'

sensu_check "memory_usage" do
  command "check-memory-percent.rb -w 85 -c 90"
  handlers [handler]
  standalone true
  interval 60
  timeout 30
  additional(:occurrences => 5, :ttl =>600)
end

sensu_check "swap_usage" do
  command "check-swap.rb -w 40 -c 60"
  handlers [handler]
  standalone true
  interval 60
  timeout 30
  additional(:occurrences => 5, :ttl =>600)
end


sensu_gem 'sensu-plugins-cpu-checks'

sensu_check "cpu_usage" do
  command "check-cpu.rb -w 80 -c 90 --sleep 15"
  handlers [handler]
  standalone true
  interval 60
  timeout 30
  additional(:occurrences => 5, :ttl =>300)
end

#Metrics CPU
sensu_gem 'sensu-plugins-load-checks'

#Metrics NIC
sensu_gem 'sensu-plugins-network-checks'
