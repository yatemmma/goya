class Logger

	LOG_FILE = 'logs/server.log'

	def self.write(message)
  	puts message
  	open(LOG_FILE, 'a') {|f| f.write "#{message}\n"}
	end
end