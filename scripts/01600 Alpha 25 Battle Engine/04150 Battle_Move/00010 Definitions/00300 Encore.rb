module Battle
  class Move
    # Move that forces the target to use the move previously used during 3 turns
    class Encore < Move
      # List of move the target cannot use with encore
      NO_ENCORE_MOVES = %i[encore mimic mirror_move sketch struggle transform]

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false if targets.empty?

        @verified = result = verify_targets(targets)
        show_usage_failure(user) unless result
        return result
      end

      private

      # Test if the move that should be forced is disallowed to be forced or not
      # @param db_symbol [Symbol]
      # @return [Boolean]
      def move_disallowed?(db_symbol)
        return NO_ENCORE_MOVES.include?(db_symbol)
      end

      # Verify all the targets and tell if the move can continue
      # @param targets [Array<PFM::PokemonBattler>]
      # @return [Boolean]
      def verify_targets(targets)
        targets.any? do |target|
          next false unless target
          next false if cant_encore_target?(target)

          next true
        end
      end

      # Tell if the target can be Encore'd
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def cant_encore_target?(target)
        last_move = target.move_history.last
        has_forced_effect = target.effects.has? { |e| e.force_next_move? && !e.dead? }
        return true if !last_move || has_forced_effect || move_disallowed?(last_move.db_symbol) || last_move.original_move.pp <= 0
        return true if target.effects.has?(:shell_trap)

        return false
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        if !@verified && verify_targets(actual_targets)
          show_usage_failure(user)
          @verified = nil
          return false
        end

        # Add effect
        actual_targets.each do |target|
          next unless target && !cant_encore_target?(target)

          move_history = target.move_history.last
          target.effects.add(effect = create_effect(move_history.original_move, target, move_history.targets))
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 559, target))
          # Poison actions
          if (index = logic.actions.find_index { |action| action.is_a?(Actions::Attack) && action.launcher == target })
            logic.actions[index] = effect.make_action
          end
        end
      end

      # Create the effect
      # @param move [Battle::Move] move that was used by target
      # @param target [PFM::PokemonBattler] target that used the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Effects::Encore]
      def create_effect(move, target, actual_targets)
        return Effects::Encore.new(logic, target, move, actual_targets)
      end
    end

    Move.register(:s_encore, Encore)
  end
end
