require 'yaml'
require 'json'

require 'clicker'
require 'observer'
require 'scenarios'
require 'result'
require 'logger'

class Goya

  include Clicker
  include Scenarios

  DIFF_X, DIFF_Y     = 3, 76
  ACTIVE_X, ACTIVE_Y = 5, 33

  def initialize(channel)
    @channel = channel
    @observer = Observer.new
    start_watching
  end

  def work(message=nil)
    Logger.write(message)
    speak(:job, "I have a new job. #{message}")
    begin
      job, *params = message.split('/')
      if job.eql? 'command'
        send(params.first)
      else
        raise 'I\'m working now!' if @is_working
        
        @is_working = true
        send(job, params)
        speak(:job, "job completed.")
        @is_working = false
      end
    rescue => e
      Logger.write("#{e.class}, #{e.message}")
      Logger.write(e.backtrace.join("\n"))
      speak(:error, e.message)
      cancel
    end
  end

  private
  def action(page, button, index=nil)
    raise "request cancelled." unless @is_working

    button = "#{button}#{index}".to_sym unless index.nil?
    x, y, *expects = get_target(page, button)

    speak(:click, page, button, expects)
    
    if expects.empty?
      button_click(x, y)
    else
      id = @observer.latest_id
      button_click(x, y)
      results = @observer.wait_for_response(id, expects)
      Result.new(results)
    end
  end

  def button_click(x, y)
    click(ACTIVE_X, ACTIVE_Y) # activate window
    move(x + DIFF_X, y + DIFF_Y)
    click(x + DIFF_X, y + DIFF_Y)
  end

  def wait(time)
    speak(:wait, time)
    sleep time
  end

  def get_target(page, button)
    @buttons = YAML.load_file('app/buttons.yml') #TODO: read once

    target_page = @buttons[page]
    raise "page not found. #{page}" if target_page.nil?
    target = target_page[button]
    raise "button not found. #{button}" if target.nil?
    target
  end

  def latest_result(uri)
    data = @observer.latest_data(uri)
    body = {:uri => "latest: #{uri}", :body => data[:body]}
    speak(:uri, body[:uri], body[:data])
    Result.new([data])
  end

  def speak(type, *params)
    case type
    when :wait
      response = {:time => params.first}
    when :job
      response = {:message => params.first}
    when :uri
      response = {:uri => params[0], :data => params[1]}
    when :click
      response = {:page => params[0], :button => params[1], :expects => params[2]}
    when :error
      response = {:message => params.first}
    else
      raise type
    end

    @channel.push response.merge({:type => type}).to_json
  end
  
  # commands
  def cursor(params=nil)
    x, y = current_position
    speak(:job, "x,y = #{x.to_i - DIFF_X}, #{y.to_i - DIFF_Y}")
  end

  def cancel
    @is_working = false
    @observer.cancel_waiting
    speak(:job, "cancelled")
  end

  def start_watching
    Thread.start do
      @observer.watching do |new_response|
        new_response.each do |response|
          uri = response[:uri].split('kcsapi')[1]
          body = {:uri => uri, :body => response[:body]}
          speak(:uri, "#{uri}", body)
        end
      end
    end
  end

  def stop_watching
    @observer.cancel_watching
  end
end