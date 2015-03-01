require 'sqlite3'
require 'yaml'

class Observer

	config = YAML.load_file('config.yml')
	DB_PATH = "#{Dir.pwd}/db/#{config[:db]}"

	def latest_id
		db = SQLite3::Database.new(DB_PATH)
		result = db.get_first_row("select * from logs order by id desc limit 1")
		db.close
		id = convert_hash(result)[:id]
	end

	def latest_data(uri)
		db = SQLite3::Database.new(DB_PATH)
		result = db.get_first_row("select * from logs where uri like '%#{uri}' order by id desc limit 1")
		db.close
		convert_hash(result)
	end

	def wait_for_response(id, expects, &block)
		@waiting = true

		SQLite3::Database.new(DB_PATH) do |db|
			60.times do
				return unless @waiting

				results = db.execute("select * from logs where id > #{id} order by id desc")
				uris = results.map {|row| convert_hash(row)[:uri].split('kcsapi')[1]}
				if (expects - uris).empty?
					return results.map {|row| convert_hash(row)}
				end
				sleep 2
			end
			raise "wait for response timed out"
		end
	end

	def cancel_waiting
		@waiting = false
	end

	def watching(&block)
		@watching = true
		id = latest_id
		SQLite3::Database.new(DB_PATH) do |db|
			while @watching
				results = db.execute("select * from logs where id > #{id} order by id desc")
				unless results.empty?
					new_rows = results.map {|row| convert_hash(row)}
					block.call(new_rows)
					id = new_rows.first[:id]
				end
				sleep 2
			end
		end
	end

	def cancel_watching
		@watching = false
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