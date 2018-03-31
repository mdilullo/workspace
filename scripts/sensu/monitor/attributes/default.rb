override["sensu"]["use_embedded_ruby"] = true
override["sensu"]["use_ssl"] = false
override["sensu"]["version"] = "0.26.5-2"
override['uchiwa']['version'] = '0.14.2-1'


#default["monitor"]["master_address"] = nil
default["monitor"]["master_address"] = "10.0.0.32"

default["monitor"]["environment_aware_search"] = false
default["monitor"]["use_local_ipv4"] = false

default["monitor"]["additional_client_attributes"] = Mash.new

default["monitor"]["use_nagios_plugins"] = false
default["monitor"]["use_system_profile"] = false
default["monitor"]["use_statsd_input"] = false

default["monitor"]["sudo_commands"] = Array.new

default["monitor"]["default_handlers"] = ["debug", "openduty", "pagerduty"]
default["monitor"]["metric_handlers"] = ["debug"]

default["monitor"]["client_extension_dir"] = "/etc/sensu/extensions/client"
default["monitor"]["server_extension_dir"] = "/etc/sensu/extensions/server"
