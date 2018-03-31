#!/usr/bin/env ruby

require 'sensu-handler'
require 'net/http'
require 'uri'

class OpendutyHandler < Sensu::Handler
  openduty = "http://localhost:8000/api/create_event"
  def incident_key
    @event['client']['name'] + '/' + @event['check']['name']
  end

  def do_request(body)
    uri = URI.parse("http://localhost:8000/api/create_event")
    request = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
    request.body = body.to_json
    # request.basic_auth 'admin', 'z3strul3s!'
    resp = Net::HTTP.start(uri.hostname, uri.port) do |http| 
  http.request(request)
    end
    case resp
    when Net::HTTPSuccess,Net::HTTPRedirection then
      { "status"=> "success" }
    else
      { "status" => "error", "message" => resp.body }
    end
  end

  def resolve_incident(desc, output)
    do_request({
      :event_type => 'resolve',
      :incident_key => incident_key,
      :service_key => '3e9dce915be153eb657de2a876ac4958757d3557',
      :details => output,
      :description => desc
    })
  end

  def trigger_incident(desc, output)
    do_request({
      :event_type => 'trigger',
      :incident_key => incident_key,
      :service_key => '3e9dce915be153eb657de2a876ac4958757d3557',
      :details => output,
      :description => desc
    })
  end

  def handle
      # puts "OPENDUTY Event #{@event}"    
      desc = @event['check']['notification']
      desc ||= [@event['client']['name'], @event['check']['name'], @event['check']['output']].join(' : ')

      begin
  puts ""
        timeout(10) do
          response = case @event['action']
            when 'create'
              trigger_incident desc, @event['check']['output']
            when 'resolve'
              resolve_incident desc, @event['check']['output']
          end
          if response['status'] == 'success'
            puts "openduty -- #{@event['action'].capitalize}d incident -- #{ incident_key  }"
          else
            puts "openduty -- Failed to #{@event['action'].capitalize} incident -- #{ incident_key  } [ #{response['message']} ]"
          end
        end
      rescue Timeout::Error
        puts "openduty -- Timedout when #{@event['action'].capitalize} incident -- #{ incident_key  }"
      end
  end
end

