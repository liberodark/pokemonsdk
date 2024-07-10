module Battle
  class Move
    class PollenPuff < Basic
      
      # Method calculating the damages done by the actual move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Integer]
      def damages(user, target)
        hp_dealt = super
        hp_dealt = 0 if logic.allies_of(user).include?(target)
        return hp_dealt
        
      end
      
      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless logic.allies_of(user).include?(target)
          next if user.effects.has?(:heal_block)
          next if target.effects.has?(:heal_block)
          
          hp = target.max_hp / 2
          logic.damage_handler.heal(target, hp)
        end
      end
    end
    Move.register(:s_pollen_puff, PollenPuff)
  end
end
