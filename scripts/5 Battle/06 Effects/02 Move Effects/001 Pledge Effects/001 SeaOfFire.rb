module Battle
  module Effects
    class SeaOfFire < PositionTiedEffectBase
      # Create a new Sea of Fire effect (Grass Pledge + Fire Pledge)
      # @param logic [Battle::Logic]
      # @param bank [Integer] bank where the effect acts
      def initialize(logic, bank)
        super(logic, bank, 0)
        self.counter = 4
        effect_creation_text
      end

      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        battlers.each do |battler|
          next if battler.bank != @bank || battler.type_fire?

          logic.damage_handler.damage_change(sea_of_fire_effect(battler), battler)
          scene.display_message_and_wait(parse_text_with_pokemon(19, 1162, battler))
        end
      end

      # Display the message associated with the effect's creation
      def effect_creation_text
        @logic.scene.display_message_and_wait(parse_text(18, 174 + bank.clamp(0, 1)))
      end

      # Method called when the Effect is deleted
      def on_delete
        @logic.scene.display_message_and_wait(parse_text(18, 176 + bank.clamp(0, 1)))
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :sea_of_fire
      end

      private

      # Return the damage dealt to a Pokémon by the Sea of Fire effect
      def sea_of_fire_effect(target)
        return (target.max_hp / 8).clamp(1, Float::INFINITY)
      end
    end
  end
end
