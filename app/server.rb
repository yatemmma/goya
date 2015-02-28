require 'eventmachine'
require 'websocket-eventmachine-server'
require 'json'
require 'yaml'

require 'goya'
require 'logger'

config = YAML.load_file('config.yml')

Logger.write("start server on #{config[:app_address]}:#{config[:app_port]}")

EM::run do
  @channel = EM::Channel.new
  @goya = Goya.new(@channel)

  WebSocket::EventMachine::Server.start(:host => config[:app_address], :port => config[:app_port]) do |ws|
    ws.onopen do
      sid = @channel.subscribe do |message|
        ws.send message
      end

      ws.onmessage do |message|
        Thread.start do
          Logger.write(message)
          begin
        	  @goya.work(JSON.parse(message))
            @channel.push "job completed. #{Time.new}"
          rescue => e
            Logger.write("#{e.class}, #{e.message}")
            Logger.write(e.backtrace.join("\n"))
            @channel.push '[error] ' + e.message
            @goya.cancel
          end
        end
      end

      ws.onclose do
        @channel.unsubscribe sid
      end
    end
  end
end
