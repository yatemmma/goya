require 'result'
require 'logger'

module Scenarios

  def login
    result = action(:common, :login).port_result
    mission_complete(result)
  end

  def back_to_port
    port_result = action(:common, :port).result(:port)
    mission_complete(port_result)
  end

  def mission_complete(port_result=nil)
    port_result = latest_result('/api_port/port').result(:port) if port_result.nil?

    decks_and_missions = port_result.complete_missions
    unless decks_and_missions.empty?
      mission_result(decks_and_missions)
      charge(decks_and_missions.map{|x| x[0, 1]}) # "1:4" => 1
      mission_start(decks_and_missions)
    end
  end
  
  # usage: mission_result(["2:3","3:5","4:9"])
  def mission_result(decks_and_missions=[])
    decks_and_missions.each do
      action(:port, :mission_result)
      action(:mission_result, :ok)
      action(:mission_result, :ok)
    end
  end

  # usage: charge([2,3,4])
  def charge(decks=[])
    action(:port, :charge)
    decks.each do |deck_id|
      action(:charge, :deck, deck_id)
      action(:charge, :select_all)
      action(:charge, :exec)
    end

    back_to_port
  end

  # usage: mission_start(["2:3","3:5","4:9"])
  def mission_start(decks_and_missions=[])
    action(:port, :battle_select)
    action(:battle_select, :mission)

    decks_and_missions.each do |deck_and_mission|
      deck_id, mission = deck_and_mission.split(":").map {|x| x.to_i}
      action(:mission, :area, ((mission-1)/8)+1)
      action(:mission, :stage, mission%8 == 0 ? 8 : mission%8)
      action(:mission, :select)
      action(:mission, :deck, deck_id)
      action(:mission, :start)
    end

    back_to_port
  end

  # usage: quest_list(["402","403","410"])
  def quest_list(missions=[])
  	result = action(:port, :quest_list).result(:quest_list)
  	action(:quest_list, :oyodo)

  	quest_list_recursive(result, missions.map{|x| x.to_i})

    back_to_port
  end

  # usage: develop(["1"])
  def develop(count=["1"])
    quest_list(["605","607"])

    action(:port, :kosho)
    count.first.to_i.times do
      action(:kosho, :develop)
      action(:develop, :bauxite_1up)
      action(:develop, :start)
      action(:develop, :ok)
    end
  end

  # usage: kenzo(["1","2"])
  def kenzo(dock_ids=["1"])
    quest_list(["606","608"])

    action(:port, :kosho)

    dock_ids.each do |dock_id|
      # TODO: complete latest_result('/api_get_member/kdock') and
      action(:kenzo, :dock, dock_id.to_i)
      action(:kenzo, :start)
    end
  end

  def kaitai(params=nil)
    quest_list(["609"])
    
    action(:port, :kosho)
    action(:kosho, :kaitai)

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
    kaitai
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
    next_result = battle_select(deck_no, area_no, stage_no).result(:start)
    
    action(:map, :compass_battle)
    
    battle_info = action(:map, :format, 1).result(:battle)

    if battle_info.has_midnight?
      wait 80 # TODO:resultから計算
      battle_result = action(:map, :midnight_no).result(:battle_result)
    else
      battle_result = action(:map, :battle_finish).result(:battle_result)
      # wait 10
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
    next_result = battle_select(deck_no, area_no, stage_no).result(:start)
    next_cell(next_result)
  end

  private
  def next_cell(next_result)
    
    action(:map, :compass, next_result.battle? ? '_battle' : '') if next_result.has_compass?

    if next_result.battle?
      # wait 10
      # format選択判定
      battle_info = action(:map, :format, 1).result(:battle)

      battle_result = nil
      if battle_info.has_midnight?
        wait 60
        battle_result = action(:map, :midnight_no).result(:battle_result)
        # action(:map, :battle_result)
      else
        battle_result = action(:map, :battle_finish).result(:battle_result)
        # wait 10
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
      next_result = action(:map, :go_next).result(:next)
      next_cell(next_result)
    end
  end

  def battle_select(deck_no, area_no, stage_no)
    action(:port, :battle_select)
    action(:battle_select, :battle)
    action(:battle, :area, area_no)
    action(:battle, :stage, stage_no)
    action(:battle, :select)
    action(:battle, :deck, deck_no)
    action(:battle, :start)
  end

  def quest_list_recursive(result, missions)
  	if result.complete_index
  		clear_result = action(:quest_list, :complete, result.complete_index).result(:clear_item)
      (clear_result.bonus_count - 1).times do #TODO: ここおかしい
        action(:quest_list, :ok)
      end
      result = action(:quest_list, :ok_last).result(:quest_list)
  		return quest_list_recursive(result, missions)
  	end

  	if missions && result.selectable?
  		index = result.quest_ids.find_index{|x| missions.include? x}
  		if index
        result = action(:quest_list, :check, index).result(:quest_list)
  		  return quest_list_recursive(result, missions)
  	  end 
  	end

  	if result.has_next_page?
  		result = action(:quest_list, :next).result(:quest_list)
  		return quest_list_recursive(result, missions)
  	end
  end
end