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
	##oldesttime = currenttime - Rational(900, 86400)
	oldesttime = currenttime - Rational(900, 86400)
	#resp = client.request 'GET', '/admin/v1/users', {limit: '10', offset:'0'}
	# Get the authentication log files
	# The strftime('%Q') returns the value in milliseconds since the unix epoch
	resp = client.request 'GET', '/admin/v1/logs/administrator', {mintime: oldesttime.strftime('%s')}
	resp_json = JSON.parse(resp.body)
	if resp_json['stat'] == 'OK'
		event.set("duo_admin", resp_json['response'])
		#event.set("zmintime", oldesttime.strftime('%c'))
		#event.set("zmaxtime", currenttime.strftime('%c'))
		return [event]
	else
		return []
	end
end