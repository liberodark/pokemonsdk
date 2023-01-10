module Battle
  class Move
    # Class describing a move hiting multiple time
    class MultiHit < Basic
      MULTI_HIT_CHANCES = [2, 2, 2, 3, 3, 5, 4, 3]
      TRIPLE_HIT_MOVES = %i[surging_strikes]
      # Function that deals the damage to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_damage(user, actual_targets)
        @user = user
        @actual_targets = actual_targets
        @nb_hit = 0
        @hit_amount = hit_amount(user, actual_targets)
        @hit_amount.times.count do |i|
          next false unless actual_targets.all?(&:alive?)
          next false if user.dead?

          @nb_hit += 1
          play_animation(user, actual_targets) if i > 0
          actual_targets.each do |target|
            hp = damages(user, target)
            @logic.damage_handler.damage_change_with_process(hp, target, user, self) do
              if critical_hit?
                scene.display_message_and_wait(actual_targets.size == 1 ? parse_text(18, 84) : parse_text_with_pokemon(19, 384, target))
              elsif hp > 0 && i == @hit_amount - 1
                efficent_message(effectiveness, target)
              end
            end
            recoil(hp, user) if recoil?
          end
          next true
        end
        @scene.display_message_and_wait(parse_text(18, 33, PFM::Text::NUMB[1] => @nb_hit.to_s))
        return false if user.dead?

        return true
      end

      # Check if this the last hit of the move
      # Don't call this method before deal_damage method call
      # @return [Boolean]
      def last_hit?
        return true if @user.dead?
        return true unless @actual_targets.all?(&:alive?)

        return @hit_amount == @nb_hit
      end

      private

      # Get the number of hit the move can perform
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Integer]
      def hit_amount(user, actual_targets)
        return 3 if TRIPLE_HIT_MOVES.include?(db_symbol)
        return 5 if user.has_ability?(:skill_link)

        return MULTI_HIT_CHANCES.sample(random: @logic.generic_rng)
      end
    end

    # Class describing a move hiting twice
    class TwoHit < MultiHit
      private

      # Get the number of hit the move can perform
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Integer]
      def hit_amount(user, actual_targets)
        return 2
      end
    end

    # This method applies for triple kick and triple axel : power ramps up but the move stops if the subsequent attack misses.
    class TripleKick < MultiHit
      # Get the real base power of the move (taking in account all parameter)
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @param i number of iterations of triple kick move
      # @return [Integer]
      def real_base_power(user, target)
        final_power = power + @nb_hit * power
        return final_power
      end

      private

      # Function that deals the damage to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_damage(user, actual_targets)
        @user = user
        @actual_targets = actual_targets
        @nb_hit = 0
        @hit_amount = hit_amount(user, actual_targets)
        @hit_amount.times.count do |i|
          next false unless actual_targets.all?(&:alive?)
          next false if user.dead?
          next false if i > 0 && !user.has_ability?(:skill_link) && (actual_targets = recalc_targets(user, actual_targets)).empty?

          play_animation(user, actual_targets) if i > 0
          actual_targets.each do |target|
            hp = damages(user, target)
            @logic.damage_handler.damage_change_with_process(hp, target, user, self) do
              if critical_hit?
                scene.display_message_and_wait(actual_targets.size == 1 ? parse_text(18, 84) : parse_text_with_pokemon(19, 384, target))
              elsif hp > 0 && i == @hit_amount - 1
                efficent_message(effectiveness, target)
              end
            end
            recoil(hp, user) if recoil?
          end
          @nb_hit += 1
          next true
        end
        @scene.display_message_and_wait(parse_text(18, 33, PFM::Text::NUMB[1] => @nb_hit.to_s))
        return false if user.dead?

        return true
      end

      # Recalculate the target each time it's needed
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] the current targets we need the accuracy recalculation on
      def recalc_targets(user, targets)
        # => proceed_move_accuracy will call display message if failure
        return [] unless proceed_move_accuracy(user, targets) || (on_move_failure(user, targets, :accuracy) && false)

        user, targets = proceed_battlers_remap(user, targets)

        actual_targets = accuracy_immunity_test(user, targets) # => Will call $scene.dislay_message for each accuracy fail
        return [] if actual_targets.none? && (on_move_failure(user, targets, :immunity) || true)

        return actual_targets
        # rubocop:enable Lint/LiteralAsCondition
      end

      def hit_amount(user, actual_targets)
        return 3
      end
    end

    Move.register(:s_multi_hit, MultiHit)
    Move.register(:s_2hits, TwoHit)
    Move.register(:s_triple_kick, TripleKick)
  end
end
