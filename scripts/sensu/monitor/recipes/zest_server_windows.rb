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

sensu_gem "sensu-plugins-windows"

sensu_check "cpu_usage" do
  command "c:/opt/sensu/embedded/bin/ruby.exe c:/opt/sensu/embedded/bin/check-windows-cpu-load.rb"
  handlers ["default"]
  standalone true
  interval 60
  timeout 30
  additional(:occurrences => 10, :ttl =>300)
end

sensu_check "memory_usage" do
  command "c:/opt/sensu/embedded/bin/ruby.exe c:/opt/sensu/embedded/bin/check-windows-ram.rb -w 80 -c 90"
  handlers ["default"]
  standalone true
  interval 60
  timeout 30
  additional(:occurrences => 10, :ttl =>300)
end

sensu_check "disk_usage" do
  command "c:/opt/sensu/embedded/bin/ruby.exe c:/opt/sensu/embedded/bin/check-windows-disk.rb -w 80 -c 90"
  handlers ["default"]
  standalone true
  interval 60
  timeout 30
  additional(:occurrences => 10, :ttl =>300)
end

