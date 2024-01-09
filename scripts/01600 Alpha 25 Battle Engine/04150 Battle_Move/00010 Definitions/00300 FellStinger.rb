module Battle
  class Move
    class FellStinger < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return actual_targets.any?(&:dead?)
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_stats(user, actual_targets)
        actual_targets.each do |target|
          next if target.alive?

          logic.stat_change_handler.stat_change_with_process(:atk, 3, user)
          if user.ability_effect.is_a?(Effects::Ability::Moxie)
            user.ability_effect.on_post_damage_death(logic.damage_handler, target.damage_history.last.damage, target, user, self)
          end
        end
      end
    end
    Move.register(:s_fell_stinger, FellStinger)
  end
end
