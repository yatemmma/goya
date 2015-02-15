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
end

# api_deck_port [x,x,x,x]
#   api_mission [1, 3, 1423836746768, 0] ?, mission_no, time, ?
class Port
  def initialize(raw_data)
    body = raw_data.find {|x| x[:uri].include? '/api_port/port'}[:body]
    @decks = body['api_data']['api_deck_port']
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