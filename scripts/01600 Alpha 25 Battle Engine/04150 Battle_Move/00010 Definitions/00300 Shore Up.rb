module Battle 
  class Move
    # Class describing a heal move
    class ShoreUp < HealMove 
      # Function that deals the heal to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] targets that will be affected by the move           
      def deal_effect(user, targets)
        targets.each do |target|
          if $env.sandstorm?
            hp = target.max_hp * 2 / 3
          else 
            hp = target.max_hp / 2
          end
          logic.damage_handler.heal(target, hp)
        end
      end
    end
    Move.register(:s_shore_up, ShoreUp)
  end
end
