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


#client_envs = search(:environment, "infrastructure:#{node.chef_environment}")
#client_envs = search(:role, "psql-master")
#client_envs.each do |client_env|
#  current = client_env.default_attributes["active"]
#  psql_config = client_env.default_attributes[current]["postgres"]
#  log "Checks for #{psql_config['database']}"
#if node['role'] == 'psql-master'
	sensu_check "#{postgres['database']}-alive" do
    command "check-postgres-alive.rb -h #{node.ipaddress} -u #{postgres['username']} -d #{postgres['database']} -p #{postgres['password']}"
    handlers [handler]
    standalone true
    interval 30
    timeout 10
    additional(:occurrences => 5, :ttl =>200) 
  end
  sensu_check "db-#{psql_config['database']}-statstable-metric" do
    type "metric"
    command "metric-postgres-statstable.rb -h #{node.ipaddress} -u #{psql_config['username']} -d #{psql_config['database']} -p #{psql_config['password']} --scheme :::name:::.postgresql"
    handlers ["graphite"]
    standalone true
    interval 30
    timeout 10
    additional(:occurrences => 5, :ttl =>200)
  end
  sensu_check "db-#{psql_config['database']}-statsdb-metric" do
    type "metric"
    command "metric-postgres-statsdb.rb -h #{node.ipaddress} -u #{psql_config['username']} -d #{psql_config['database']} -p #{psql_config['password']} --scheme :::name:::.postgresql"
    handlers ["graphite"]
    standalone true
    interval 30
    timeout 10
    additional(:occurrences => 5, :ttl =>200)
  end
  sensu_check "db-#{psql_config['database']}-connections-metric" do
    type "metric"
    command "metric-postgres-connections.rb -h #{node.ipaddress} -u #{psql_config['username']} -d #{psql_config['database']} -p #{psql_config['password']} --scheme :::name:::.postgresql"
    handlers ["graphite"]
    standalone true
    interval 30
    timeout 10
    additional(:occurrences => 5, :ttl =>200)
  end
  sensu_check "db-#{psql_config['database']}-connections" do
    command "check-postgres-connections.rb -w 400 -c 450 -h #{node.ipaddress} -u #{psql_config['username']} -d #{psql_config['database']} -p #{psql_config['password']}"
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
    command "check_postgres.pl -H #{node.ipaddress} -u #{psql_config['username']} -db #{psql_config['database']} --dbpass #{psql_config['password']} --warning=#{q_warning} --critical=#{q_critical} --action=query_time"
    handlers ["slack"]
    standalone true
    interval 30
    timeout 15
    additional(:ttl =>200, :slack => { :channels => ["#zest-query-#{node['postgres-role']}"]})
  end
#end

if node['postgres-role'] == 'slave' 

##
 if  node["recovery_of"] != nil
    masters = search(:node, "chef_environment:#{node["recovery_of"]} AND postgres-role:master")
    Chef::Application.fatal('No cluster master found', 2) if masters.to_a.empty?
  else
    masters = search(:node, "chef_environment:#{node.chef_environment} AND postgres-role:master")
    Chef::Application.fatal('No cluster master found', 2) if masters.to_a.empty?
  end
##
#  masters = search(:node, "chef_environment:#{node.chef_environment} AND roles:postgres AND postgres-role:master")
  client_envs.each do |client_env|
    current = client_env.default_attributes["active"]
    psql_config = client_env.default_attributes[current]["postgres"]
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
  end
end

##Monitor Crontab jobs.
#if node["postgres-role"] == "master"
#sensu_check "check_cron_delete_archive" do
#      command "check-mtime.rb -f /tmp/delete-archive-sensu.cron -w 86400 -c 90000"
#      handlers [handler]
#       standalone true
#      interval 60
#      timeout 10
#      additional(:notification => "Delete Archive File not run.",:occurrences => 5, :ttl =>200)
#    end
#sensu_check "check_cron_master_snapshot" do
#      command "check-mtime.rb -f /tmp/master-snapshot-sensu.cron -w 86400 -c 108000"
#      handlers [handler]
#      standalone true
#      interval 60
#      timeout 10
#      additional(:notification => "Master SnapShot not run.",:occurrences => 5, :ttl =>200)
#    end
#end

#if node["postgres-role"] == "slave"
#sensu_check "check_cron_pg_backup_rotated" do
#      command "check-mtime.rb -f /tmp/slave-snapshot-sensu.cron -w 86400 -c 108000"
#      handlers [handler]
#      standalone true
#      interval 60
#      timeout 10
#      additional(:notification => "Postgres Backup Rotated not run.",:occurrences => 5, :ttl =>200)
#    end
#end
