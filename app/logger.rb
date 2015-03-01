class Logger
  LOG_FILE = 'logs/server.log'

  def self.write(message)
    puts message
    open(LOG_FILE, 'a') {|f| f.write "#{message}\n"}
  end

  def self.error(e)
    self.write("#{e.class}, #{e.message}")
    self.write(e.backtrace.join("\n"))
  end
end