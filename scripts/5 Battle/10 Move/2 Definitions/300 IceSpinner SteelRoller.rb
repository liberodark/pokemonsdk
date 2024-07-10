module Battle
  class Move
    # Implement the Ice Spinner move
    class IceSpinner < Basic
      # Function that deals the effect
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        logic.fterrain_change_handler.fterrain_change_with_process(:none)
      end

      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return !@logic.field_terrain_effect.none?
      end
    end
    # Implement the Stell Roller move
    class SteelRoller < IceSpinner
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if @logic.field_terrain_effect.none?

        return true
      end
    end
    Move.register(:s_ice_spinner, IceSpinner)
    Move.register(:s_steel_roller, SteelRoller)
  end
end
