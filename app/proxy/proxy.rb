require 'webrick'
require 'webrick/httpproxy'
require 'net/http'
require 'uri'
require 'json'
require 'sqlite3'
require 'yaml'

config = YAML.load_file(ARGV[0] ||= 'config.yml')
LOG_FILE_PATH  = Dir.pwd + '/logs/proxy.log'
DATABASE_PATH  = Dir.pwd + '/db/' + config[:db]

logger = WEBrick::Log::new(LOG_FILE_PATH, WEBrick::Log::DEBUG)

unless File.exist?(DATABASE_PATH)
  system("sqlite3 #{DATABASE_PATH} < db/create_tables.sql")
end

handler = Proc.new do |req, res|
	if (req.unparsed_uri.include? '/kcsapi/') && (res.content_type.eql? 'text/plain')
		sql = "insert into logs values (NULL, :uri, :query, :body, :created_at, :updated_at)"
		db = SQLite3::Database.new(DATABASE_PATH)
		db.execute(
			sql, 
			:uri   => req.unparsed_uri, 
			:query => req.query.to_json, 
			:body  => res.body.to_s.sub(/svdata=/, ""),
			:created_at => Time.now.to_s,
			:updated_at => Time.now.to_s
			)
		db.close
		logger.debug("saved: #{req.unparsed_uri}")
	end
end

server = WEBrick::HTTPProxyServer.new(
	:BindAddress => config[:app_address],
	:Port        => config[:proxy_port],
	:ProxyVia    => false,
	:Logger      => logger,
	:AccessLog   => [], # mute
	:ServerType  => WEBrick::Daemon,
	:ProxyContentHandler => handler
)

Signal.trap('INT') do
	server.shutdown
end

server.start
