require 'logger'

class Result

  def initialize(results)
  	@raw = results
  end

  def port_result
    Port.new(@raw)
  end

  def quest_list_result
    QuestList.new(@raw)
  end

  def clear_item_result
    ClearItem.new(@raw)
  end

  def mapcell_result
    MapCell.new(@raw)
  end

  def next_result
    Next.new(@raw)
  end

  def battle_info
    BattleInfo.new(@raw)
  end

  def battle_result
    BattleResult.new(@raw)
  end
end

class BattleResult
  def initialize(raw_data)
    @body = raw_data.find {|x| x[:uri].include?('/api_req_sortie/battleresult')}[:body]
    @result = @body['api_data']
  end

  def get_ship?
    not @result['api_get_ship'].nil?
  end
end

class BattleInfo
  def initialize(raw_data)
    @body = raw_data.find {|x| x[:uri].include?('/api_req_sortie/battle')}[:body]
    @battle = @body['api_data']
  end

  def has_midnight?
    @battle['api_midnight_flag'].to_i == 1
  end

  def hps
    nowhps = @battle['api_nowhps'].map{|x| x.to_i}
    maxhps = @battle['api_maxhps'].map{|x| x.to_i}
    ship_now = nowhps[1,6]
    ship_hps   = nowhps.zip(maxhps)[1,6]
    ship_hps_percent   = ship_hps.map   {|x| (x[0].to_f/x[1]*100).to_i}

    if @battle['api_stage_flag'][2].to_i == 1 # airplane
      ship_damages   = @battle['api_kouku']['api_stage3']['api_fdam'].map{|x| x.to_i}[1,6]
      enemie_damages = @battle['api_kouku']['api_stage3']['api_edam'].map{|x| x.to_i}[1,6]
      Logger.write("--airplane")
      Logger.write(ship_damages)
      Logger.write(enemie_damages)
      ship_now = [ship_now, ship_damages].transpose.map{|a| a.inject(:-)}
    end
    # TODO: help
    if @battle['api_opening_flag'].to_i == 1 # opening attack
      ship_damages   = @battle['api_opening_atack']['api_fdam'].map{|x| x.to_i}[1,6]
      enemie_damages = @battle['api_opening_atack']['api_edam'].map{|x| x.to_i}[1,6]
      Logger.write("--opening attack")
      Logger.write(ship_damages)
      Logger.write(enemie_damages)
      ship_now = [ship_now, ship_damages].transpose.map{|a| a.inject(:-)}
    end
    if @battle['api_hourai_flag'][0].to_i == 1 # hougeki1
      index   = @battle['api_hougeki1']['api_df_list'].map{|x| x[0].to_i}
      damages = @battle['api_hougeki1']['api_damage'].map{|x| x[0].to_i}
      list = index.zip(damages)
      list.shift
      Logger.write("--hougeki")
      Logger.write(list)
      list.each {|x| ship_now[x[0]-1] -= x[1] unless ship_now[x[0]-1].nil?}
      # ship_now = [ship_now, ship_damages].transpose.map{|a| a.inject(:-)}
    end
    # TODO: hougeki2
    # TODO: hougeki3
    if @battle['api_hourai_flag'][3].to_i == 1 # raigeki
      ship_damages   = @battle['api_raigeki']['api_fdam'].map{|x| x.to_i}[1,6]
      enemie_damages = @battle['api_raigeki']['api_edam'].map{|x| x.to_i}[1,6]
      Logger.write("--raigeki")
      Logger.write(ship_damages)
      Logger.write(enemie_damages)
      ship_now = [ship_now, ship_damages].transpose.map{|a| a.inject(:-)}
    end
    Logger.write("--start")
    Logger.write(ship_hps)
    Logger.write(ship_hps_percent)
    ship_hps = ship_now.zip(maxhps[1,6])
    ship_hps_percent = ship_hps.map {|x| (x[0].to_f/x[1]*100).to_i}
    Logger.write("--end")
    Logger.write(ship_hps)
    Logger.write(ship_hps_percent)
  end
end

class Next
  def initialize(raw_data)
    @body = raw_data.find {|x| 
      x[:uri].include?('/api_req_map/start') || x[:uri].include?('/api_req_map/next')
    }[:body]
    @next = @body['api_data']
  end

  def battle?
    @next['api_color_no'].to_i == 4
  end

  def has_compass?
    @next['api_rashin_flg'].to_i == 1
  end
end

class MapCell
  def initialize(raw_data)
    @body = raw_data.find {|x| x[:uri].include? '/api_get_member/mapcell'}[:body]
  end

  def get_cells
    cells = @body['api_data']
    cells.map {|cell| {:id => cell['api_id'], :passed => cell['api_passed']}}
  end
end

# api_deck_port [x,x,x,x]
#   api_mission [1, 3, 1423836746768, 0] ?, mission_no, time, ?
class Port
  def initialize(raw_data)
    @body = raw_data.find {|x| x[:uri].include? '/api_port/port'}[:body]
    @decks = @body['api_data']['api_deck_port']
  end

  def complete_missions
    missions = @decks.map {|deck| deck['api_mission']}

    @decks.select {|deck|
      deck['api_mission'].first == 2
    }.map {|deck|
      "#{deck['api_id']}:#{deck['api_mission'][1]}"
    }
  end
end

class QuestList
  def initialize(raw_data)
    @body = raw_data.find {|x| x[:uri].include? '/api_get_member/questlist'}[:body]

    @quests = @body['api_data']['api_list'].reject {|x| x == -1}
  end

  def has_next_page?
    current_page = @body['api_data']['api_disp_page'].to_i
    page_count   = @body['api_data']['api_page_count'].to_i
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
    @body['api_data']['api_exec_count'].to_i < 5
  end
end

# api_bounus [xxx]
# api_bounus_count 1
# api_material [30,30,30,30]
class ClearItem
  def initialize(raw_data)
    @body = raw_data.find {|x| x[:uri].include? '/api_req_quest/clearitemget'}[:body]
  end

  def bonus_count
    @body['api_data']['api_bounus_count'].to_i
  end
end