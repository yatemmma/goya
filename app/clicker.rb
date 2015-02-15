module Clicker
	
	def current_position
		result = `cliclick p`
    result.split(":")[1].strip.split(",")
	end

	def move(x, y)
		system("cliclick \"m:#{x},#{y}\"")
	end

	def click(x, y)
		system("cliclick \"c:#{x},#{y}\"")
	end
end