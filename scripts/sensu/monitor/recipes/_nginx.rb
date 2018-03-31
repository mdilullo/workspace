#
# Cookbook Name:: monitor
# Recipe:: nginx
#
# Copyright 2013, Kwarter, Inc.
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
sensu_gem 'sensu-plugins-nginx'


sensu_check 'nginx-process' do
  command "check-procs.rb -f #{node[:nginx][:pid]}"
  handlers ['default']
  subscribers ['nginx']
  interval 30
end

sensu_check 'nginx-metrics' do
  command 'nginx-metrics.rb --url http://localhost:8090/nginx_status --scheme zest.:::name:::.nginx'
  type 'metric'
  handlers ['metrics']
  subscribers ['nginx']
  interval 30
end

pidfile = "/var/run/nginx.pid"
if node[:nginx]
  pidfile = node[:nginx][:pid]
end

sensu_check 'nginx-limits' do
  command "check-limits.rb -p %s -f -W 10000 -C 1025" % pidfile
  handlers ['default']
  subscribers ['nginx']
  interval 30
end

sensu_check "suricata-events" do
  command "check-log.rb -s /tmp/cache/check-log -f /var/log/suricata/fast.log  -q Priority -w '1' -c '2'"
  handlers ["default"]
  standalone true
  auto_resolve false
  interval 30
  timeout 30
  additional(:occurrences => 1, :ttl =>300)
end
