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
  end

  def speak(message)
    @channel.push message
  end

  def work(message=nil)
    if message['job'].eql? 'cancel'
      cancel
    elsif message['job'][0, 1].eql? '/'
      latest_result(message['job'])
    else
      speak "**** I have a new job. #{message}"
      do_job(message)
    end
  end

  def cancel
    raise 'I have no job.' unless working_now?
    @is_working = false
    @observer.cancel
  end

  private
  def do_job(message)
    raise 'I\'m working now!' if working_now?
    raise 'Invalid job' if message['job'].empty?

    Logger.write("do_job #{message}")

    job, *params = message['job'].split('/')

    @is_working = true
    send(job, params)
    @is_working = false
  end

  def working_now?
    @is_working
  end

  def action(page, button, index=nil)
    raise "request cancelled." unless working_now?

    button = "#{button.to_s}#{index}".to_sym unless index.nil?

    x, y, *expects = get_target(page, button)

    if expects.empty?
      speak "click #{page} => #{button}"
      button_click(x, y)
    else
      id = @observer.latest_id
      speak "click #{page} => #{button} expects:#{expects}"
      button_click(x, y)
      results = @observer.wait_for_response(id, expects) do |responses|
        responses.each {|response|
          uri = response[:uri].split('kcsapi')[1]
          body = {:uri => uri, :body => response[:body]}
          speak "#{uri}"
          speak "raw=#{body.to_json}"
        }
      end
      Result.new(results)
    end
  end

  def button_click(x, y)
    click(ACTIVE_X, ACTIVE_Y) # activate window
    move(x + DIFF_X, y + DIFF_Y)
    click(x + DIFF_X, y + DIFF_Y)
  end

  def wait(time)
    speak "wait #{time}"
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
    speak "raw=#{body.to_json}"
    Result.new([data])
  end
  
  def cursor(params=nil)
    x, y = current_position
    speak "x,y = #{x.to_i - DIFF_X}, #{y.to_i - DIFF_Y}"
  end
end