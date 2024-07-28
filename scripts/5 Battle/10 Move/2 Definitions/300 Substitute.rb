module Battle
  class Move
    # Move that put the mon into a substitute
    class Substitute < BasicWithSuccessfulEffect
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        if user.max_hp < factor
          show_usage_failure(user)
          return false
        end

        if user.hp_rate <= (1.0 / factor)
          usage_message(user)
          scene.display_message_and_wait(parse_text_with_pokemon(18, 129, user))
          return false
        end

        if user.effects.has?(:substitute)
          usage_message(user)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 788, user))
          return false
        end

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do
          next if user.hp_rate <= (1.0 / factor)

          hp = (user.max_hp / factor).floor
          logic.damage_handler.damage_change(hp, user)
          user.effects.add(Effects::Substitute.new(logic, user))
          scene.display_message_and_wait(parse_text_with_pokemon(19, 785, user))
        end
      end

      # Play the move animation
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      def play_animation(user, targets)
        return scene.visual.battler_sprite(user.bank, user.position).switch_to_substitute_sprite unless $options.show_animation

        @scene.visual.set_info_state(:move_animation)
        @scene.visual.wait_for_animation
        logic.scene.visual.battler_sprite(user.bank, user.position).switch_to_substitute_animation
        scene.visual.wait_for_animation
        @scene.visual.set_info_state(:move, targets + [user])
        @scene.visual.wait_for_animation
      end

      private

      # The divisor used to calculate the HP cost for creating a substitute (1/4 of max HP)
      # @return [Integer]
      def factor
        return 4
      end
    end

    # Move that put the mon into a substitute and switches it out, giving its sub to the incoming Pokémon
    class ShedTail < Substitute
      # Tell if the move is a move that switch the user if that hit
      def self_user_switch?
        return true
      end

      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super
        return show_usage_failure(user) && false unless @logic.switch_handler.can_switch?(user, self)

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        super
        actual_targets.each do |target|
          target.effects.add(Battle::Effects::ShedTail.new(logic, target))
          logic.request_switch(target, nil)
        end
      end

      # The divisor used to calculate the HP cost for creating a substitute (1/4 of max HP)
      # @return [Integer]
      def factor
        return 2
      end
    end
    Move.register(:s_substitute, Substitute)
    Move.register(:s_shed_tail, ShedTail)
  end
end
