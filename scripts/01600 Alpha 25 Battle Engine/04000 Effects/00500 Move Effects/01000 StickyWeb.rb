module Battle
  module Effects
    class StickyWeb < PositionTiedEffectBase
      # The Pokemon that launched the attack
      # @return [PFM::PokemonBattler]
      attr_reader :origin
      # Create a new Sticky Web effect
      # @param logic [Battle::Logic]
      # @param bank [Integer] bank where the effect acts
      # @param origin [PFM::PokemonBattler] the Pokemon that launched the attack
      def initialize(logic, bank, origin)
        super(logic, bank, origin.position)
        @origin = origin
      end

      # Function that tells if the move is affected by Rapid Spin
      # @return [Boolean]
      def rapid_spin_affected?
        return true
      end

      # Get the effect name
      # @return [Symbol]
      def name
        return :sticky_web
      end

      # Function called when the effect has been deleted from the effects handler
      def on_delete
        @logic.scene.display_message_and_wait(parse_text(18, @bank == 0 ? 216 : 217))
      end

      # Function called when a Pokemon has actually switched with another one
      # @param handler [Battle::Logic::SwitchHandler]
      # @param who [PFM::PokemonBattler] Pokemon that is switched out
      # @param with [PFM::PokemonBattler] Pokemon that is switched in
      def on_switch_event(handler, who, with)
        return unless with.grounded?
        return if with.has_ability?(:magic_guard)
        return if with.hold_item?(:heavy_duty_boots)

        handler.scene.display_message_and_wait(message(with))
        handler.logic.stat_change_handler.stat_change_with_process(:spd, -1, with, with.has_ability?(:mirror_armor) ? origin : nil)
      end

      # Get the message text
      # @param pokemon [PFM::PokemonBattler]
      # @return [String]
      def message(pokemon)
        return parse_text_with_pokemon(19, 1222, pokemon)
      end
    end
  end
end
