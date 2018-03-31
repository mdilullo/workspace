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

group "devops" do
  append true
  members "sensu"
end

sensu_gem 'sensu-plugins-java'

handler = node["sensu"]["handler"]

cookbook_file "/etc/sensu/plugins/check-application.rb" do
  source "plugins/check-application.rb"
  mode 0755
end

node_layer = node['layer_name']
node_server = node['server_name']
base_port = node['tomcat']['port']
defs = node['app_servers'][node_layer][node_server]['servers']

defs.each do |name,tomcat|
  port = base_port + tomcat['offset']
  tomcat.apps.each do |app_name, app|
    sensu_check "#{name}-#{app_name}" do
      command "check-application.rb -h localhost -u tomcat -w tomcat -a #{app_name} -p #{port}"
      handlers [handler]
      standalone true
      interval 60
      additional(:notification => "#{app_name} is not running", :occurrences => 5, :refresh => 300)
    end

    if name != "webapps"
      sensu_check "#{name}-#{app_name}-metrics" do
        type "metric"
        command "sudo -u tomcat7 metrics-jstat.rb -j #{app_name} -g #{node.chef_environment}.#{node.name}.jvm -H #{name}"
        handlers ["graphite"]
        standalone true
        interval 30
      end
    end
  end
end
