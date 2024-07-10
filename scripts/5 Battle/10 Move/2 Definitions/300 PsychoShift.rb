module Battle
  class Move
    class PsychoShift < Move
      private

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        if targets.all? { |target| target.effects.has?(:substitute) } || right_status_symbol(user).nil?
          return show_usage_failure(user) && false
        end

        return true
      end

      # Test if the target is immune
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def target_immune?(user, target)
        return true unless logic.status_change_handler.status_appliable?(right_status_symbol(user), target, user, self)
        return true if target.has_ability?(:comatose)

        return super
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.effects.has?(:substitute)
          
          logic.status_change_handler.status_change(right_status_symbol(user), target, user, self)
          logic.status_change_handler.status_change(:cure, user, user, self)
        end
      end        

      # Get the right symbol for a status of a Pokemon
      # @param pokemon [PFM::PokemonBattler]
      # @return [Symbol]
      def right_status_symbol(pokemon)
        return Configs.states.symbol(pokemon.status)
      end
    end
    Move.register(:s_psycho_shift, PsychoShift)
  end
end
