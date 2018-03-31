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

handler = node['sensu']['handler']

# build and install postgresql into the sensu embedded install
ark 'postgresql' do
  url 'https://ftp.postgresql.org/pub/source/v9.4.6/postgresql-9.4.6.tar.bz2'
end

package 'libreadline-dev' do
  action :install
end

cookbook_file "/etc/sensu/plugins/check_postgres.pl" do
  source "plugins/check_postgres.pl"
  mode 0755
end

execute 'configure postgresql' do
  command './configure --prefix /opt/sensu/embedded --with-openssl'
  not_if '/opt/sensu/embedded/bin/gem list pg -i'
  cwd '/usr/local/postgresql'
  environment(
    CFLAGS: '-I/opt/sensu/embedded/include',
    LDFLAGS: '-L/opt/sensu/embedded/lib'
  )
  notifies :run, 'execute[make postgresql]', :immediately
end

execute 'make postgresql' do
  command 'make'
  cwd '/usr/local/postgresql'
  action :nothing
  notifies :run, 'execute[make install postgresql]', :immediately
end

execute 'make install postgresql' do
  command 'make install'
  cwd '/usr/local/postgresql'
  action :nothing
end
sensu_gem 'pg'
sensu_gem 'sensu-plugins-filesystem-checks'

sensu_gem 'sensu-plugins-postgres' do
  version '0.1.1'
end


log "POSTGRES MONITORING AGENT #{node['postgres-role']}"
if  node["recovery_of"] != nil
    client_envs = search(:environment, "infrastructure:#{node["recovery_of"]}")
  else
    client_envs = search(:environment, "infrastructure:#{node.chef_environment}")
  end


client_envs = search(:node, 'roles:psql-master AND chef_environment:fresh')
psql_config = "postgres"

sensu_check "db-#{psql_config['database']}-alive" do
	command "check-postgres-alive.rb -h [hostname] -u [username] -d [database] -p [password]"
	handlers [handler]
	standalone true
	interval 30
	timeout 10
	additional(:occurrences => 5, :ttl =>200)
													  end
sensu_check "db-#{psql_config['database']}-statstable-metric" do
    type "metric"
    command "metric-postgres-statstable.rb -h hostname-u ['username'] -d ['database'] -p ['password'] --scheme :::name:::.postgresql"
    handlers ["graphite"]
    standalone true
    interval 30
	timeout 10
	additional(:occurrences => 5, :ttl =>200)
end

sensu_check "db-#{psql_config['database']}-statsdb-metric" do
    type "metric"
    command "metric-postgres-statsdb.rb -h hostname-u ['username'] -d ['database'] -p ['password'] --scheme :::name:::.postgresql"
    handlers ["graphite"]
	standalone true
	interval 30
	timeout 10
	additional(:occurrences => 5, :ttl =>200)
end

sensu_check "db-#{psql_config['database']}-connections-metric" do
    type "metric"
    command "metric-postgres-connections.rb -h hostname-u ['username'] -d ['database'] -p ['password'] --scheme :::name:::.postgresql"
    handlers ["graphite"]
    standalone true
	interval 30
	timeout 10
	additional(:occurrences => 5, :ttl =>200)
end

sensu_check "db-#{psql_config['database']}-connections-metric" do
    type "metric"
    command "metric-postgres-connections.rb -h hostname-u ['username'] -d ['database'] -p ['password'] --scheme :::name:::.postgresql"
	handlers ["graphite"]
	standalone true
    interval 30
	timeout 10
	additional(:occurrences => 5, :ttl =>200)
end

sensu_check "db-#{psql_config['database']}-connections" do
    command "check-postgres-connections.rb -w 400 -c 450 -h hostname-u ['username'] -d ['database'] -p ['password']"
    handlers [handler]
    standalone true
	interval 30
	timeout 10
	additional(:occurrences => 5, :ttl =>200)
end
			
    q_warning = '30s'
	q_critical = '2m'
	if node['postgres-role'] =='slave'
	    q_warning = '10m'
	    q_critical = '15m'
	end
								
sensu_check "db-#{psql_config['database']}-query-time" do
    command "check_postgres.pl -H hostname-u ['username'] -db ['database'] --dbpass ['password'] --warning=#{q_warning} --critical=#{q_critical} --action=query_time"
	handlers ["slack"]
	standalone true
	interval 30
	timeout 15
end
								
sensu_check "db-#{psql_config['database']}-graphite" do
    command "metric-postgres-graphite.rb -m #{masters.first.ipaddress} -s #{node.ipaddress} -u #{psql_config['username']} -d #{psql_config['database']} -p #{psql_config['password']}"
    handlers ["graphite"]
    type "metric"
    standalone true
    interval 30
    timeout 10
    additional(:occurrences => 5, :ttl =>200)
end

sensu_check "db-#{psql_config['database']}-replication" do
    command "check-postgres-replication.rb -m #{masters.first.ipaddress} -s #{node.ipaddress} -u #{psql_config['username']} -d #{psql_config['database']} -p #{psql_config['password']}"
    handlers [handler]
    standalone true
    interval 30
    timeout 10
    additional(:occurrences => 5, :ttl =>200)
end