module Battle
  class Move
    # Abstract class that manage logic of stage swapping moves
    class StatAndStageEdit < Move
      private

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return super && targets.any? { |target| !target.effects.has?(:out_of_reach)}
      end

      # Event called if the move failed
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @param reason [Symbol] why the move failed: :usable_by_user, :accuracy, :immunity, :pp
      def on_move_failure(user, targets, reason)
        show_usage_failure(user)
        return super
      end

      # Return the chance of hit of the move
      # @return [Float]
      def chance_of_hit(user, target)
        return 100 unless target.effects.has?(:out_of_reach) && be_method == :s_roar

        super
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          edit_stages(user, target)
        end
        return true
      end

      # Apply the swap
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      def edit_stages(user, target)
        log_error("Poorly implemented move: edit_stages(user, target) should have been overwritten in child class")
      end
    end
  end
end
