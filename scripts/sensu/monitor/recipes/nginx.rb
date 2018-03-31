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
sensu_gem 'sensu-plugins-process-checks'

handler = node['sensu']['handler']

sensu_check 'nginx-process' do
  command "check-process.rb -p nginx -W 1"
  handlers [handler]
  subscribers ['nginx']
  interval 30
  standalone true
  timeout 30
  additional(:occurrences => 1, :ttl =>300)
end

pidfile = "/var/run/nginx.pid"
if node[:nginx]
  pidfile = node[:nginx][:pid]
end

# sensu_check 'metrics-nginx' do
  # command 'metrics-nginx.rb --url http://localhost:8090/nginx_status --scheme zest.:::name:::.nginx'
  # type 'metric'
  # handlers ['graphite']
  # subscribers ['nginx']
  # standalone true
  # interval 30
  # timeout 30
  # additional(:occurrences => 1, :ttl =>300)
# end
file "/etc/sensu/conf.d/checks/metrics-nginx.json" do
  action :delete
end

sensu_check "suricata-events" do
  command "check-log.rb -s /tmp/cache/check-log -f /var/log/suricata/fast.log  -q 'Priority: [12]' -w '1' -c '2'"
  handlers [handler]
  standalone true
  interval 30
  timeout 30
  additional(:occurrences => 1, :ttl =>300, :auto_resolve =>false)
end
