require 'eventmachine'
require 'websocket-eventmachine-server'
require 'yaml'

require 'goya'

config = YAML.load_file('config.yml')

Logger.write("start server on #{config[:app_address]}:#{config[:app_port]}")

EM::run do
  @channel = EM::Channel.new
  @goya = Goya.new(@channel)

  WebSocket::EventMachine::Server.start(
                            :host => config[:app_address],
                            :port => config[:app_port]) do |ws|
    ws.onopen do
      sid = @channel.subscribe do |message|
        ws.send message
      end

      ws.onmessage do |message|
        Thread.start do
          @goya.work(message)
        end
      end

      ws.onclose do
        @channel.unsubscribe sid
      end
    end
  end
end
