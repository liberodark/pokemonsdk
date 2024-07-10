module Battle
  class Move
    # Flower Heal move
    class FloralHealing < HealMove
      # Function that deals the heal to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, targets)
        targets.each do |target|
          hp = @logic.field_terrain_effect.grassy? ? target.max_hp * 2 / 3 : target.max_hp / 2
          logic.damage_handler.heal(target, hp)
        end
      end
    end
    Move.register(:s_floral_healing, FloralHealing)
  end
end
