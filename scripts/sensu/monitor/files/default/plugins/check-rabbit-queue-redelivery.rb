#!/usr/bin/env ruby

#
# RabbitMQ Overview Metrics
# ===
#
# Dependencies
# -----------
# - RabbitMQ `rabbitmq_management` plugin
# - Ruby gem `carrot-top`
#
# Overview stats
# ---------------
# RabbitMQ 'overview' stats are similar to what is shown on the main page
# of the rabbitmq_management web UI. Example:
#
#   $ rabbitmq-queue-metrics.rb
#    host.rabbitmq.queue_totals.messages.count 0 1344186404
#    host.rabbitmq.queue_totals.messages.rate  0.0 1344186404
#    host.rabbitmq.queue_totals.messages_unacknowledged.count  0 1344186404
#    host.rabbitmq.queue_totals.messages_unacknowledged.rate 0.0 1344186404
#    host.rabbitmq.queue_totals.messages_ready.count 0 1344186404
#    host.rabbitmq.queue_totals.messages_ready.rate  0.0 1344186404
#    host.rabbitmq.message_stats.publish.count 4605755 1344186404
#    host.rabbitmq.message_stats.publish.rate  17.4130186829638  1344186404
#    host.rabbitmq.message_stats.deliver_no_ack.count  6661111 1344186404
#    host.rabbitmq.message_stats.deliver_no_ack.rate 24.6867565643405  1344186404
#    host.rabbitmq.message_stats.deliver_get.count 6661111 1344186404
#    host.rabbitmq.message_stats.deliver_get.rate  24.6867565643405  1344186404#
#
# Copyright 2012 Joe Miller - https://github.com/joemiller
#
# Released under the same terms as Sensu (the MIT license); see LICENSE
# for details.

require 'rubygems' if RUBY_VERSION < '1.9.0'
require 'sensu-plugin/check/cli'
require 'socket'
require 'carrot-top'
require 'pp'

class RabbitMQMetrics < Sensu::Plugin::Check::CLI

  option :host,
    :description => "RabbitMQ management API host",
    :long => "--host HOST",
    :default => "localhost"

  option :port,
    :description => "RabbitMQ management API port",
    :long => "--port PORT",
    :proc => proc {|p| p.to_i},
    :default => 15672

  option :user,
    :description => "RabbitMQ management API user",
    :long => "--user USER",
    :default => "guest"

  option :password,
    :description => "RabbitMQ management API password",
    :long => "--password PASSWORD",
    :default => "guest"

  option :ssl,
    :description => "Enable SSL for connection to the API",
    :long => "--ssl",
    :boolean => true,
    :default => false

  option :warn,
    :description => "Warning number of messages/sec",
    :long => "--warn MSGS_SEC",
    :proc => proc {|a| a.to_i },
    :default => 10
  option :crit,
    :description => "Critical number of messages/sec",
    :long => "--crit MSGS_SEC",
    :proc => proc {|a| a.to_i },
    :default => 20


  def get_rabbitmq_info
    begin
      rabbitmq_info = CarrotTop.new(
        :host => config[:host],
        :port => config[:port],
        :user => config[:user],
        :password => config[:password],
        :ssl => config[:ssl]
      )
    rescue
      warning "could not get rabbitmq info"
    end
    rabbitmq_info
  end

  def run
    rabbitmq = get_rabbitmq_info
    warnings = 0
    criticals = 0
    errors = Array.new

    queues = rabbitmq.queues

    queues.each do |q|
      if q.has_key?('message_stats') && q['message_stats'].has_key?('redeliver_details')
        # ap q['message_stats']
        rate = q['message_stats']['redeliver_details']['rate']
        if rate > config[:crit]
          criticals += 1
          errors << "#{q['name']}@#{q['vhost']} redeliery > #{rate}"
        elsif rate > config[:warn]
          warnings += 1
          errors << "#{q['name']}@#{q['vhost']} redeliery > #{rate}"
        end
      end
    end

    if criticals > 0
      critical errors.join("-")
    elsif warnings > 0
      warning errors.join("-")
    else
      ok
    end
  end

end
