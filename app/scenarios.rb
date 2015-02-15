require 'result'
require 'logger'

module Scenarios

  def back_to_port(params=nil)
    result = action(:common, :port).port_result

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
    wait 0.5
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
      wait 7
    end

    back_to_port
  end

  # usage: quest_list(["402","403","410"])
  def quest_list(missions=nil)
  	result = action(:port, :quest_list).quest_list_result
  	action(:quest_list, :oyodo)
  	sleep 2

  	quest_list_recursive(result, missions.map{|x| x.to_i})

    back_to_port
  end

  private
  def quest_list_recursive(result, missions)
  	if result.complete_index
  		clear_result = action(:quest_list, :complete, result.complete_index).clear_item_result
      (clear_result.bonus_count - 1).times do
        action(:quest_list, :ok)
        wait 0.5
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