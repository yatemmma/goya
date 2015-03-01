require 'result'
require 'logger'

module Scenarios

  def login(params=nil)
    result = action(:common, :login).port_result
    wait 3
    mission_complete(result)    
  end

  def back_to_port(params=nil)
    result = action(:common, :port).port_result

    mission_complete(result)    
  end

  def mission_complete(result)
    result = latest_result('/api_port/port').port_result if result.kind_of?(Array)

    decks_and_missions = result.complete_missions
    unless decks_and_missions.empty?
      mission_result(decks_and_missions)
      charge(decks_and_missions.map{|x| x[0, 1]}) # "1:4" => 1
      mission_start(decks_and_missions)
    end
  end
  
  # usage: mission_result(["2:3","3:5","4:9"])
  def mission_result(decks_and_missions=[])
    decks_and_missions.each do
      wait 0.5
      action(:port, :mission_result)
      wait 7
      action(:mission_result, :ok)
      wait 1
      action(:mission_result, :ok)
      wait 1
    end
  end

  # usage: charge([2,3,4])
  def charge(decks=[])
    action(:port, :charge)
    wait 1

    decks.each do |deck_id|
      action(:charge, :deck, deck_id)
      wait 0.5
      action(:charge, :select_all)
      wait 0.5
      action(:charge, :exec)
    end

    back_to_port
  end

  # usage: mission_start(["2:3","3:5","4:9"])
  def mission_start(decks_and_missions=[])
    action(:port, :battle_select)
    wait 1
    action(:battle_select, :mission)
    wait 1

    decks_and_missions.each do |deck_and_mission|
      deck_id, mission = deck_and_mission.split(":").map {|x| x.to_i}
      action(:mission, :area, ((mission-1)/8)+1)
      wait 0.5
      action(:mission, :stage, mission%8 == 0 ? 8 : mission%8)
      wait 0.5
      action(:mission, :select)
      wait 0.5
      action(:mission, :deck, deck_id)
      wait 0.5
      action(:mission, :start)
      wait 6
    end

    back_to_port
  end

  # usage: quest_list(["402","403","410"])
  def quest_list(missions=nil)
  	result = action(:port, :quest_list).quest_list_result
  	action(:quest_list, :oyodo)
  	wait 2

  	quest_list_recursive(result, missions.map{|x| x.to_i})

    back_to_port
  end

  # usage: develop(["1"])
  def develop(count=["1"])
    quest_list(["605","607"]) # TODO: 3times

    action(:port, :kosho)
    wait 1
    count.first.to_i.times do
      action(:kosho, :develop)
      wait 1
      action(:develop, :bauxite_1up)
      wait 0.5
      action(:develop, :start)
      wait 10
      action(:develop, :ok)
      wait 2
    end
  end

  # usage: kenzo(["1","2"])
  def kenzo(dock_ids=["1"])
    quest_list(["606","608"])

    action(:port, :kosho)
    wait 1

    dock_ids.each do |dock_id|
      # TODO: complete latest_result('/api_get_member/kdock') and
      action(:kenzo, :dock, dock_id.to_i)
      wait 1
      action(:kenzo, :start)
      wait 3
    end
  end

  def kaitai(params=nil)
    quest_list(["609"])
    
    action(:port, :kosho)
    wait 1
    action(:kosho, :kaitai)
    wait 1

    # TODO: not implement yet

    back_to_port
  end

  def develop_scenario1(params=nil)
    develop(["1"])
    kenzo(["1"])
    develop(["3"])
    kenzo(["2"])
  end

  def develop_scenario2(params=nil)
    kenzo(["1", "2"])
    # break
  end

  def kira(param=nil)
    # not implemented yet
  end

  def black_reveling(param=nil)
    # TODO: ship select
    # TODO: max ship check
    deck_no  = 1
    area_no  = 3
    stage_no = 2
    next_result = battle_select(deck_no, area_no, stage_no).next_result
    wait 5
    
    action(:map, :compass) if next_result.has_compass?
    wait 10
    
    battle_info = action(:map, :format, 1).battle_info
    battle_info.hps

    if battle_info.has_midnight?
      wait 80 # TODO:resultから計算
      battle_result = action(:map, :midnight_no).battle_result
      wait 10
    else
      battle_result = action(:map, :battle_finish).battle_result
      wait 10
    end

    action(:map, :result_ok)
    wait 5
    action(:map, :result_ok)
    wait 10 if battle_result.get_ship?
    action(:map, :result_ok) if battle_result.get_ship?
    wait 2
    result = action(:map, :back).port_result

    mission_complete(result)

    charge(["#{deck_no}"])
  end

  def oryol_cruising(param=nil)
    # TODO: ship select
    # TODO: max ship check
    deck_no  = 1
    area_no  = 2
    stage_no = 3
    next_result = battle_select(deck_no, area_no, stage_no).next_result
    wait 5
    next_cell(next_result)
    
  end

  private
  def next_cell(next_result)
    action(:map, :compass) if next_result.has_compass?
    if next_result.battle?
      wait 10
      # format選択判定
      battle_info = action(:map, :format, 1).battle_info
      battle_info.hps

      battle_result = nil
      if battle_info.has_midnight?
        wait 60
        battle_result = action(:map, :midnight_no).battle_result
        wait 10
        # action(:map, :battle_result)
      else
        battle_result = action(:map, :battle_finish).battle_result
        wait 10
      end

      action(:map, :result_ok)
      wait 5
      action(:map, :result_ok)
      wait 10 if battle_result.get_ship?
      action(:map, :result_ok) if battle_result.get_ship?
      wait 2

      # 大破判定
      # action(:map, :next)
      # wait 3
      # next_cell(next_result)
    else
      next_result = action(:map, :go_next).next_result
      next_cell(next_result)
    end
  end

  def battle_select(deck_no, area_no, stage_no)
    action(:port, :battle_select)
    wait 0.5
    action(:battle_select, :battle)
    wait 0.5
    action(:battle, :area, area_no)
    wait 0.5
    action(:battle, :stage, stage_no)
    wait 0.5
    action(:battle, :select)
    wait 0.5
    action(:battle, :deck, deck_no)
    wait 1
    action(:battle, :start)
  end

  def quest_list_recursive(result, missions)
  	if result.complete_index
  		clear_result = action(:quest_list, :complete, result.complete_index).clear_item_result
      wait 3
      (clear_result.bonus_count - 1).times do #TODO: ここおかしい
        action(:quest_list, :ok)
        wait 3
      end
      result = action(:quest_list, :ok_last).quest_list_result
      wait 2
  		return quest_list_recursive(result, missions)
  	end

  	if missions && result.selectable?
  		index = result.quest_ids.find_index{|x| missions.include? x}
  		if index
        result = action(:quest_list, :check, index).quest_list_result
  		  return quest_list_recursive(result, missions)
  	  end 
  	end

  	if result.has_next_page?
  		result = action(:quest_list, :next).quest_list_result
  		return quest_list_recursive(result, missions)
  	end
  end
end