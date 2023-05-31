module Battle
  class Move
    class GlitzyGlow < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return !@logic.bank_effects[user.bank].has?(effect)
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        turn_count = user.hold_item?(:light_clay) ? 8 : 5
        @logic.bank_effects[user.bank].add(class_effect.new(@logic, user.bank, 0))
        @scene.display_message_and_wait(parse_text(18, message + user.bank.clamp(0, 1)))
      end

      # Get the effect to check
      def effect
        :light_screen
      end

      # Get the new effect to deal
      def class_effect
        Effects::LightScreen
      end

      # Get the message to display
      def message
        134
      end
    end

    class BaddyBad < GlitzyGlow
      # Get the effect to check
      def effect
        :reflect
      end

      # Get the new effect to deal
      def class_effect
        Effects::Reflect
      end

      # Get the message to display
      def message
        130
      end
    end
    Move.register(:s_glitzy_glow, GlitzyGlow)
    Move.register(:s_baddy_bad, BaddyBad)
  end
end
