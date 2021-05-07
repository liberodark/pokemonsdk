module Battle
  module Effects
    # Implement the Aqua Ring effect
    class AquaRing < PokemonTiedEffectBase
      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        return @scene.display_message_and_wait(fail_message) if @pokemon.effects.has?(:heal_block)

        heal_hp = (@pokemon.max_hp / hp_factor).clamp(1, Float::INFINITY)
        heal_hp += heal_hp * 30 / 100 if @pokemon.hold_item?(:big_root)
        @logic.scene.visual.show_hp_animations([@pokemon], [heal_hp])
        @logic.scene.display_message_and_wait(message)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :aqua_ring
      end

      private

      # Get the message text
      # @return [String]
      def message
        return parse_text_with_pokemon(19, 604, @pokemon)
      end

      # Get the message text when a heal fail because of Heal Block
      # @return [String]
      def fail_message
        return parse_text_with_pokemon(19, 890, @pokemon)
      end

      # Get the HP factor delt by the move
      # @return [Integer]
      def hp_factor
        return 16
      end
    end
  end
end
