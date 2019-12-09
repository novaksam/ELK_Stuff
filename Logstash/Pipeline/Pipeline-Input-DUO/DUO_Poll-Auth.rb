require_relative 'duo_api'
require 'json'
require 'date'

def register(params)
	@ikey = params["IKEY"]
	@skey = params["SKEY"]
	@host = params["HOST"]
end

def filter(event)
	client= DuoApi.new(@ikey,@skey,@host)
	# Get the current time
	currenttime = DateTime.now
	#currenttime = currenttime1 - 7
	# We subtract 180 seconds from the 'now' time 
	# to allow for processes time gaps while
	# not creating excessive duplication
	oldesttime = currenttime - Rational(900, 86400)
	#resp = client.request 'GET', '/admin/v1/users', {limit: '10', offset:'0'}
	# Get the authentication log files
	# The strftime('%Q') returns the value in milliseconds since the unix epoch
	resp = client.request 'GET', '/admin/v2/logs/authentication', {mintime: oldesttime.strftime('%Q'), maxtime: currenttime.strftime('%Q'), limit: '1000'}
	resp_json = JSON.parse(resp.body)
	if resp_json['response']['metadata']['total_objects'] != 0
		event.set("duo_auth", resp_json['response'])
		#event.set("zmintime", oldesttime.strftime('%c'))
		#event.set("zmaxtime", currenttime.strftime('%c'))
		return [event]
	else
		return []
	end
end