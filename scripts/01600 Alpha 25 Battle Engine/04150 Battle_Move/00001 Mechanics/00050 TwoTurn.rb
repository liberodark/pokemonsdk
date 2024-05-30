module Battle
  class Move
    module Mechanics
      # Move that takes two turns
      #
      # **REQUIREMENTS**
      # None
      module TwoTurn
        private

        # Internal procedure of the move
        # @param user [PFM::PokemonBattler] user of the move
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        # @note If you are interrupted (see: interrupted?), we must reset @turn; otherwise,
        #       we will proceed to phase 2 the next time we make a move in two turns.
        def proceed_internal(user, targets)
          # rubocop:disable Lint/LiteralAsCondition
          @turn = nil unless user.effects.has?(&:force_next_move?)

          # Piece of proceed_internal_precheck(user, targets)
          unless move_usable_by_user(user, targets) || (on_move_failure(user, targets, :usable_by_user) && false)
            kill_turn1_effects(user)
            user.add_move_to_history(self, targets)
            return nil
          end

          usage_message(user)

          if targets.all?(&:dead?) && (on_move_failure(user, targets, :no_target) || true)
            kill_turn1_effects(user)
            scene.display_message_and_wait(parse_text(18, 106))
            user.add_move_to_history(self, targets)
            return nil
          end

          if pp == 0 && !(user.effects.has?(&:force_next_move?) && !@forced_next_move_decrease_pp)
            kill_turn1_effects(user)
            (scene.display_message_and_wait(parse_text(18, 85)) || true) && on_move_failure(user, targets, :pp)
            user.add_move_to_history(self, targets)
            return nil
          end

          # End of Piece of proceed_internal_precheck

          @turn = (@turn || 0) + 1

          # Loading Turn
          if @turn == 1
            decrease_pp(user, targets)
            play_animation_turn1(user, targets)
            proceed_message_turn1(user, targets)
            deal_effects_turn1(user, targets)
            @scene.visual.set_info_state(:move_animation)
            @scene.visual.wait_for_animation
            return prepare_turn2(user, targets) unless shortcut?(user, targets)

            @turn += 1
          end

          # Execution Turn
          if @turn >= 2
            @turn = nil
            execution_turn(user, targets)
          end
          # rubocop:enable Lint/LiteralAsCondition
        end

        # TwoTurn Move execution procedure
        # @param user [PFM::PokemonBattler] user of the move
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        def execution_turn(user, targets)
          # rubocop:disable Lint/LiteralAsCondition
          # Piece of proceed_internal_precheck(user, targets)
          # => proceed_move_accuracy will call display message if failure
          unless !(actual_targets = proceed_move_accuracy(user, targets)).empty? || (on_move_failure(user, targets, :accuracy) && false)
            kill_turn1_effects(user)
            user.add_move_to_history(self, targets)
            return nil
          end

          user, actual_targets = proceed_battlers_remap(user, actual_targets)
          actual_targets = accuracy_immunity_test(user, actual_targets) # => Will call $scene.dislay_message for each accuracy fail
          if actual_targets.none? && (on_move_failure(user, targets, :immunity) || true)
            kill_turn1_effects(user)
            user.add_move_to_history(self, actual_targets)
            return nil
          end

          # Piece of super proceed_internal(user, targets)
          post_accuracy_check_effects(user, actual_targets)

          post_accuracy_check_move(user, actual_targets)

          play_animation(user, targets)
          kill_turn1_effects(user)

          deal_damage(user, actual_targets) &&
            effect_working?(user, actual_targets) &&
            deal_status(user, actual_targets) &&
            deal_stats(user, actual_targets) &&
            deal_effect(user, actual_targets)

          user.add_move_to_history(self, actual_targets)
          user.add_successful_move_to_history(self, actual_targets)
          @scene.visual.set_info_state(:move_animation)
          @scene.visual.wait_for_animation
          # rubocop:enable Lint/LiteralAsCondition
        end

        # Check if the two turn move is executed in one turn
        # @param user [PFM::PokemonBattler] user of the move
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        # @return [Boolean]
        def shortcut?(user, targets)
          @logic.each_effects(user) do |effect|
            return true if effect.on_two_turn_shortcut(user, targets, self)
          end
          return false
        end
        alias two_turns_shortcut? shortcut?

        # Add the effects to the pokemons (first turn)
        # @param user [PFM::PokemonBattler] user of the move
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        def deal_effects_turn1(user, targets)
          stat_changes_turn1(user, targets)&.each do |(stat, value)|
            @logic.stat_change_handler.stat_change_with_process(stat, value, user)
          end
        end
        alias two_turn_deal_effects_turn1 deal_effects_turn1

        # Give the force next move and other effects
        # @param user [PFM::PokemonBattler] user of the move
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        def prepare_turn2(user, targets)
          user.effects.add(Effects::ForceNextMoveBase.new(@logic, user, self, targets, turn_count))
          user.effects.add(Effects::OutOfReachBase.new(@logic, user, self, can_hit_moves)) if can_hit_moves
        end
        alias two_turn_prepare_turn2 prepare_turn2

        # Remove effects from the first turn
        # @param user [PFM::PokemonBattler]
        def kill_turn1_effects(user)
          user.effects.get(&:force_next_move?).kill if user.effects.has?(&:force_next_move?)
          user.effects.get(&:out_of_reach?).kill if user.effects.has?(&:out_of_reach?)
        end
        alias two_turn_kill_turn1_effects kill_turn1_effects

        # Display the message and the animation of the turn
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        def proceed_message_turn1(user, targets)
          nil
        end

        # Display the message and the animation of the turn
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        def play_animation_turn1(user, targets)
          play_substitute_swap_animation(user)
          return unless $options.show_animation
        end

        # Return the stat changes for the user
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        # @return [Array<Array<[Symbol, Integer]>>] exemple : [[:dfe, -1], [:atk, 1]]
        def stat_changes_turn1(user, targets)
          nil
        end

        # Return the list of the moves that can reach the pokemon event in out_of_reach, nil if all attack reach the user
        # @return [Array<Symbol>]
        def can_hit_moves
          nil
        end

        # Return the number of turns the effect works
        # @return Integer
        def turn_count
          return 2
        end
      end
    end
  end
end
