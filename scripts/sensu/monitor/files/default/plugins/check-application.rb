#!/usr/bin/env ruby

require 'sensu-plugin/check/cli'
require 'net/http'
require 'timeout'

class ZestAppCheck < Sensu::Plugin::Check::CLI

  check_name 'zest_application_check' # defaults to class name
  option :host, :short => '-h HOST', :default => 'localhost'
  option :port, :short => '-p PORT', :default => 8080, proc: proc(&:to_i)
  option :appname, :short => '-a APP'
  option :username, :short => '-u USERNAME'
  option :password, :short => '-w PASSWORD'

  def run
    begin
      Timeout.timeout(4) do
        acquire_resource
      end
    rescue Timeout::Error
      critical 'Request timed out'
    rescue => e
      critical "Request error: #{e.message}"
    end
  end

  def acquire_resource
    http = Net::HTTP.new(config[:host], config[:port])

    req = Net::HTTP::Get.new("/manager/text/list", 'User-Agent' => "Sensu-Check")
    req.basic_auth config[:username], config[:password]

    res = http.request(req)
    case res.code
    when /^2/
      # if line = res.body.match(/^.*:#{config[:appname]}$/)
      if line = res.body.match(/^.*:.*#{config[:appname]}(\.war)?$/)
        (path, state, n, name) = line[0].split(':')
        if state == "running"
          ok("App #{config[:appname]} is #{state}")
        else
          critical("App #{config[:appname]} is #{state}")
        end
      else
        critical("App #{config[:appname]} not deployed")
      end
    when /^4/, /^5/
      critical("Received #{res.code}")
    else
      warning("Received #{res.code}")
    end

  end

end
