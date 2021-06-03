module Battle
  class Move
    module Mechanics
      # Move that takes two turns
      #
      # **REQUIREMENTS**
      # None
      module TwoTurn
        # Function that tests if the user is able to use the move
        # @param user [PFM::PokemonBattler] user of the move
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
        # @return [Boolean] if the procedure can continue
        def move_usable_by_user(user, targets)
          return move_usable_by_user_turn1(super, user, targets) unless user.effects.has?(&:force_next_move?)

          return move_usable_by_user_turn2(super, user, targets)
        end

        private

        # @param super_result [Boolean] the result of original method
        # @param user [PFM::PokemonBattler] user of the move
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
        # @return [Boolean] if the procedure can continue
        def move_usable_by_user_turn1(super_result, user, targets)
          return true if check_shortcut_turn1(user, targets)

          proceed_effects_turn1(user, targets)
          proceed_message_turn1(user, targets)
          proceed_animation_turn1(user, targets)
          return false
        end
        alias two_turn_move_usable_by_user_turn1 move_usable_by_user_turn1

        # @param super_result [Boolean] the result of original method
        # @param user [PFM::PokemonBattler] user of the move
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
        # @return [Boolean] if the procedure can continue
        def move_usable_by_user_turn2(super_result, user, targets)
          remove_effects_turn2(user, targets)
          return false unless super_result

          return true
        end
        alias two_turn_move_usable_by_user_turn2 move_usable_by_user_turn2

        # Check if the user can skip the first move
        # @param user [PFM::PokemonBattler] user of the move
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        # @return [Boolean] true if the move is actually one move
        def check_shortcut_turn1(user, targets)
          if user.hold_item?(:power_herb)
            @scene.display_message_and_wait(parse_text_with_pokemon(19, 1028, user, PFM::Text::ITEM2[1] => user.item_name))
            @logic.item_change_handler.change_item(:none, true, user)
            return true
          end
          return false
        end
        alias two_turn_check_shortcut_turn1 check_shortcut_turn1

        # Add the effects to the pokemons (first turn)
        # @param user [PFM::PokemonBattler] user of the move
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        def proceed_effects_turn1(user, targets)
          user.effects.add(Effects::ForceNextMoveBase.new(@logic, user, self, targets))
          user.effects.add(Effects::OutOfReachBase.new(@logic, user, can_hit_moves)) if can_hit_moves
          stat_changes_turn1(user, targets)&.each do |(stat, value)|
            @logic.stat_change_handler.stat_change_with_process(stat, value, user)
          end
        end
        alias two_turn_proceed_effects_turn1 proceed_effects_turn1

        # Display the message and the animation of the turn
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        def proceed_message_turn1(user, targets)
          nil
        end
        alias two_turn_proceed_message_turn1 proceed_message_turn1

        # Display the message and the animation of the turn
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        def proceed_animation_turn1(user, targets)
          nil
        end
        alias two_turn_proceed_animation_turn1 proceed_animation_turn1

        # Return the stat changes for the user 
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        # @return [Array<Array<[Symbol, Integer]>>] exemple : [[:dfe, -1], [:atk, 1]]
        def stat_changes_turn1(user, targets)
          nil
        end
        alias two_turn_stat_changes_turn1 stat_changes_turn1

        # Remove effects on turn 2
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>] expected targets
        def remove_effects_turn2(user, targets)
          user.effects.get(&:out_of_reach?)&.kill
          user.effects.deleted_dead_effects
        end
        alias two_turn_remove_effect_turn2 remove_effects_turn2

        # Return the list of the moves that can reach the pokemon event in out_of_reach, nil if all attack reach the user
        # @return [Array<Symbol>]
        def can_hit_moves
          nil
        end
      end
    end
  end
end
