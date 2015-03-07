require 'logger'

URLS = {
  :port => '/api_port/port',
  :quest_list => '/api_get_member/questlist',
  :battle => '/api_req_sortie/battle',
  :battle_result => '/api_req_sortie/battleresult',
  :start => '/api_req_map/start',
  :next => '/api_req_map/next',
  :map_cell => '/api_get_member/mapcell',
  :clear_item => '/api_req_quest/clearitemget',
  :kdock => '/api_get_member/kdock',
  :kousyou_getship => '/api_req_kousyou/getship',
  :master => '/api_start2',
}

class Array # responses array
  def each_result(&block)
    self.each do |result|
      sym, uri = URLS.find {|k, v| v.eql?(result[:uri])}
      if sym.nil?
        block.call(Result.new(result))
      else
        block.call(self.result(sym))
      end
    end
  end

  def result(sym)
    result = self.find {|x| x[:uri].eql?(URLS[sym])}
    class_name = sym.to_s.split("_").map{|x| x.capitalize}.join
    eval(class_name).new(result)
  end

  def add_blank12
    self + (12 - self.size).times.map{0}
  end
end

class Result
  attr :raw_data, :uri, :data, :id

  def initialize(response)
    @raw_data = response
    @uri = @raw_data[:uri]
    @data = @raw_data[:body]['api_data']
    @id = @raw_data[:id].to_i
  end

  def show_info
    []
  end
end

# api_deck_port [x,x,x,x]
#   api_mission [1, 3, 1423836746768, 0] ?, mission_no, time, ?
class Port < Result
  def show_info
    info = []
    info << "complete_missions:#{complete_missions}" unless complete_missions.empty?
    info << "decks: #{decks}"
    info
  end

  def complete_missions
    decks = @data['api_deck_port']
    missions = decks.map {|deck| deck['api_mission']}

    decks.select {|deck|
      deck['api_mission'].first == 2
    }.map {|deck|
      "#{deck['api_id']}:#{deck['api_mission'][1]}"
    }
  end

  def ships
    # ships={};master.body.api_data.api_mst_ship.each(function(x){ships[x.api_id] = x.api_name})
    # port.body.api_data.api_ship.map(function(x){return {ship: ships[x.api_ship_id], lv:x.api_lv}})
    @data['api_ship'].map do |x|
      {
        :id => x['api_id'].to_i,
        :level => x['api_lv'].to_i,
        :name => $master.ship(x['api_ship_id'].to_i)[:name]
      }
    end
  end

  def decks
    @data['api_deck_port'].map {|x| x['api_ship']}
  end
end

class QuestList < Result
  def initialize(response)
    super
    @quests = @data['api_list'].reject {|x| x == -1}
  end

  def show_info
    []
  end
  
  def has_next_page?
    current_page = @data['api_disp_page'].to_i
    page_count   = @data['api_page_count'].to_i
    current_page < page_count
  end

  def quest_ids
    ids = @quests.map {|x| x['api_no'].to_i if x['api_state'].to_i == 1}
    Logger.write(ids)
    ids
  end

  def complete_index
    @quests.find_index {|x| x['api_state'].to_i == 3}
  end

  def selectable?
    @data['api_exec_count'].to_i < 5
  end
end

class Battle < Result
  def initialize(response)
    super
    @max_hps   = @data['api_maxhps'].map{|x| x.to_i}[1..-1]
    @start_hps = @data['api_nowhps'].map{|x| x.to_i}[1..-1]
    @final_hps = inject_damages
    @final_percent = hp_percent
  end

  def show_info
    [
      "airplane_damages: #{airplane_damages}",
      "opening_damages: #{opening_damages}",
      "hougeki1_damages: #{hougeki_damages(1)}",
      "hougeki2_damages: #{hougeki_damages(2)}",
      "hougeki3_damages: #{hougeki_damages(3)}",
      "raigeki_damages: #{raigeki_damages}",
      "start_hps: #{@start_hps.zip(@max_hps)}",
      "final_hps: #{@final_hps.zip(@max_hps)}",
      "final_percent: #{@final_percent}",
      "hp_status: #{hp_status}",
    ]
  end

  def has_midnight?
    @data['api_midnight_flag'].to_i == 1
  end

  def inject_damages
    [
      @start_hps,
      Array(airplane_damages  ).add_blank12,
      Array(opening_damages   ).add_blank12,
      Array(hougeki_damages(1)).add_blank12,
      Array(hougeki_damages(2)).add_blank12,
      Array(hougeki_damages(3)).add_blank12,
      Array(raigeki_damages   ).add_blank12,
    ].transpose.map{|x| x.inject(:-)}
  end

  def hp_percent
    @final_hps.zip(@max_hps).map do |x|
      final, max = x
      (final.to_f/max*100).to_i
    end
  end

  def hp_status
    @final_percent.map do |x|
      case x
      when 76..100 then ''
      when 51..75 then '*'
      when 27..50 then '**'
      when  1..26 then '***'
      else '-'
      end
    end
  end

  def airplane_damages
    if @data['api_stage_flag'][2].to_i == 1
      ship_damages   = @data['api_kouku']['api_stage3']['api_fdam'].map{|x| x.to_i}[1..-1]
      enemie_damages = @data['api_kouku']['api_stage3']['api_edam'].map{|x| x.to_i}[1..-1]
      ship_damages + enemie_damages
    end
  end

  def opening_damages
    if @data['api_opening_flag'].to_i == 1
      ship_damages   = @data['api_opening_atack']['api_fdam'].map{|x| x.to_i}[1..-1]
      enemie_damages = @data['api_opening_atack']['api_edam'].map{|x| x.to_i}[1..-1]
      ship_damages + enemie_damages
    end
  end

  def hougeki_damages(no)
    if @data['api_hourai_flag'][0].to_i == no
      index   = @data["api_hougeki#{no}"]['api_df_list'].map{|x| x[0].to_i}[1..-1]
      damages = @data["api_hougeki#{no}"]['api_damage'].map{|x| x[0].to_i}[1..-1]
      
      total = [-1].add_blank12
      list = index.zip(damages)
      list.each do |x|
        i, value = x
        total[i] += value
      end
      total[1..-1]
    end
  end

  def raigeki_damages
    if @data['api_hourai_flag'][3].to_i == 1
      ship_damages   = @data['api_raigeki']['api_fdam'].map{|x| x.to_i}[1..-1]
      enemie_damages = @data['api_raigeki']['api_edam'].map{|x| x.to_i}[1..-1]
      ship_damages + enemie_damages
    end
  end
end

class BattleResult < Result
  def show_info
    [
      "get_ship?: #{get_ship?}"
    ]
  end

  def get_ship?
    not @data['api_get_ship'].nil?
  end
end

class Start < Result
  def show_info
    [
      "battle?: #{battle?}",
      "has_compass?: #{has_compass?}"
    ]
  end

  def battle?
    @data['api_color_no'].to_i == 4
  end

  def has_compass?
    @data['api_rashin_flg'].to_i == 1
  end
end

class Next < Start
end

class MapCell < Result
  def show_info
    []
  end

  def get_cells
    @data.map {|cell| {:id => @data['api_id'], :passed => @data['api_passed']}}
  end
end

class ClearItem < Result
  def show_info
    [
      "bonus_count: #{bonus_count}"
    ]
  end

  def bonus_count
    Logger.write("[DEBUG] bonus_count: #{@data['api_bounus_count'].to_i}")
    Logger.write("[DEBUG] api_bounus: #{@data['api_bounus'].size}")
    @data['api_bounus_count'].to_i
  end

  def got_box?
    not @data['api_bounus'].select {|x|
      not x['api_item']['api_name'].empty?
    }.empty?
  end
end

class Kdock < Result
  def initialize(response)
    super
    @kdocks = @data
  end

  def show_info
    [
      "dock_status: #{dock_status}",
      "#{complete_dock_ids.map {|id| $master.ship(id)}}"
    ]
  end

  def dock_status
    @kdocks.map {|x| x['api_state']}
  end

  def complete_dock_ids
    @kdocks.select {|x| x['api_state'].to_i == 3}.map {|x| x['api_id'].to_i}
  end

  def building_dock_ids
    @kdocks.select {|x| (1..2).include? x['api_state'].to_i}.map {|x| x['api_id'].to_i}
  end
end

class KousyouGetship < Kdock
  def initialize(response)
    super
    @kdocks = @data['api_kdock']
  end
end

class Master < Result
  def initialize(response)
    super
    @m_ships = @data['api_mst_ship']
  end

  def ship(ship_id)
    ship = @m_ships.find {|x| x['api_id'].to_i == ship_id}
    {
      :id => ship_id,
      :name => ship['api_name']
    }
  end
end
