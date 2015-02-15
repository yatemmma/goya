task :default => :start

desc 'get to work!'
task :start => ['proxy:start', 'server:start']

desc 'reward from admiral'
task :stop => ['proxy:stop', 'server:stop']

desc 'go to next cruising!'
task :restart => [:stop, :start]

namespace :proxy do
	exec_file = 'app/proxy.rb'
	pid_file  = 'pids/proxy.pid'

	desc 'start proxy server'
	task :start do
		start_server(exec_file, pid_file)
	end

	desc 'stop proxy server'
	task :stop do
		stop_server(pid_file)
	end

	desc 'restart proxy server'
	task :restart => [:stop, :start]
end

namespace :server do
	exec_file = 'app/server.rb'
	pid_file  = 'pids/server.pid'

	desc 'start websocket server'
	task :start do
		start_server(exec_file, pid_file, true)
	end

	desc 'stop websocket server'
	task :stop do
		stop_server(pid_file)
	end

	desc 'restart websocket server'
	task :restart => [:stop, :start]
end

def start_server(exec_file, pid_file, nohup=false)
	cmd = "bundle exec ruby -I app #{exec_file}"
	cmd = "nohup #{cmd} &" if nohup
	puts cmd
	system(cmd)

	cmd_pid = "pid=`ps aux | grep #{exec_file} | grep -v grep | awk '{print $2}'`;"
	cmd_pid << "if [ x != ${pid}x ]; then echo ${pid} > #{pid_file}; fi"
	puts cmd_pid
	system(cmd_pid)
end

def stop_server(pid_file)
	cmd_kill = "kill `cat #{pid_file}`"
	puts cmd_kill
	system(cmd_kill)

	cmd_rm = "rm -f #{pid_file}"
	puts cmd_rm
	system(cmd_rm)
end