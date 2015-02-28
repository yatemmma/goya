require 'sqlite3'
require 'yaml'

class Observer

	def initialize
		config = YAML.load_file('config.yml')
		@db_path = Dir.pwd + '/db/' + config[:db]
		@cancelled = false
	end

	def latest_id
		db = SQLite3::Database.new(@db_path)
		result = db.get_first_row("select * from logs order by id desc limit 1")
		db.close
		id = convert_hash(result)[:id]
	end

	def latest_data(uri)
		db = SQLite3::Database.new(@db_path)
		result = db.get_first_row("select * from logs where uri like '%#{uri}' order by id desc limit 1")
		db.close
		convert_hash(result)
	end

	def wait_for_response(id, expects, &block)
		@cancelled = false
		db = SQLite3::Database.new(@db_path)
		60.times do
			return if @cancelled

			results = db.execute("select * from logs where id > #{id} order by id desc")
			block.call(results.map {|row| convert_hash(row)}) unless results.empty?
			uris = results.map {|row| convert_hash(row)[:uri].split('kcsapi')[1]}
			if (expects - uris).empty?
				db.close
				return results.map {|row| convert_hash(row)}
			end
			sleep 2
		end
		db.close
		raise "wait for response timed out"
	end

	def cancel
		@cancelled = true
	end

	private
	def convert_hash(array)
		keys = [:id, :uri, :query, :body, :created_at, :updated_at]
		h = Hash[*[keys, array].transpose.flatten]
		h[:body] = JSON.parse(h[:body])
		h[:query] = JSON.parse(h[:query])
		h
	end
end