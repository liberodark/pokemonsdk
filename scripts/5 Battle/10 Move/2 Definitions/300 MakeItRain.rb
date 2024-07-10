module Battle
  class Move
    # class managing Make It Rain move
    class MakeItRain < SelfStat
      private
      
      # Function that deals the effect (generates money the player gains at the end of battle)
      # @param user [PFM::PokemonBattler] user of the move
      # @param _actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        return unless user.from_party?
        
        money = user.level * 5
        total_money = money * actual_targets.size
        
        scene.battle_info.additional_money += total_money
        
        scene.display_message_and_wait(parse_text(18, 128))
      end
    end
    
    Move.register(:s_make_it_rain, MakeItRain)
  end
end
