module Battle
  class Move
    # Class that manage the Yawn skill, works together with the Effects::Drowsiness class
    # @see https://bulbapedia.bulbagarden.net/wiki/Yawn_(move)
    class Yawn < Move
      private

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        target_with_ability = @logic.foes_of(user).find { |target| %i[sweet_veil flower_veil].include?(target.battle_ability_db_symbol) }

        if target_with_ability
          @logic.scene.visual.show_ability(target_with_ability)
          show_usage_failure(user)
          return false
        end
        

        if targets.any? { |target| @logic.bank_effects[target.bank].has?(:safeguard) ||
          %i[electric_terrain misty_terrain].include?(logic.field_terrain) && target.grounded?
        }
          return show_usage_failure(user) && false
        end

        return true
      end

      # Function that tests if the targets blocks the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] expected target
      # @note Thing that prevents the move from being used should be defined by :move_prevention_target Hook.
      # @return [Boolean] if the target evade the move (and is not selected)
      def move_blocked_by_target?(user, target)
        return true if super
        return failure_message(target) if target.status?
        return failure_message(target) if %i[drowsiness substitute].any? { |db_symbol| target.effects.has?(db_symbol) } || target.status?
        return failure_message(target) if %i[insomnia vital_spirit comatose].include?(target.battle_ability_db_symbol)
        return failure_message(target) if ($env.sunny? || $env.hardsun?) && target.has_ability?(:leaf_guard)
        return failure_message(target) if target.db_symbol == :minior && target.form == 0

        return false
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.effects.has?(:drowsiness)
  
          target.effects.add(Effects::Drowsiness.new(@logic, target, turn_count, user))
        end
      end

      # Return the turn countdown before the effect proc (including the current one)
      # @return [Integer]
      def turn_count
        2
      end

      # Display failure message
      # @param target [PFM::PokemonBattler] expected target
      # @return [Boolean] true if blocked
      def failure_message(target)
        @logic.scene.display_message_and_wait(parse_text_with_pokemon(59, 2048, target))
        return true
      end
    end
    Move.register(:s_yawn, Yawn)
  end
end
