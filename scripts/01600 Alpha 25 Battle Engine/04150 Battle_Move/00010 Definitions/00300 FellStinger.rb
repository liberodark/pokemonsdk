module Battle
  class Move
    class FellStinger < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return !actual_targets.empty? && actual_targets.first.dead?
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_stats(user, actual_targets)
        logic.stat_change_handler.stat_change_with_process(:atk, 3, user)
        if user.ability_effect.is_a?(Effects::Ability::Moxie) && logic.stat_change_handler.stat_increasable?(:atk, user)
          scene.visual.show_ability(user)
          logic.stat_change_handler.stat_change_with_process(:atk, 1, user)
        end
      end
    end
    Move.register(:s_fell_stinger, FellStinger)
  end
end
