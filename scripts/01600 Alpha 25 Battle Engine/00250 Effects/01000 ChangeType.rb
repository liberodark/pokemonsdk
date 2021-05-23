module Battle
  module Effects
    # ChangeType Effects
    class ChangeType < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param type [Integer] the ID of the type to apply to the Pokemon
      def initialize(logic, pokemon, type)
        super(logic, pokemon)
        @type = type
        @original_type = [@pokemon.type1, @pokemon.type2, @pokemon.type3]
        @pokemon.type1 = @type
        @pokemon.type2 = @pokemon.type3 = 0
      end

      # Function called when a Pokemon has actually switched with another one
      # @param handler [Battle::Logic::SwitchHandler]
      # @param who [PFM::PokemonBattler] Pokemon that is switched out
      # @param with [PFM::PokemonBattler] Pokemon that is switched in
      def on_switch_event(_handler, who, _with)
        return unless @pokemon == who

        restore_original_types
      end

      # Function called when a Pokemon initialize a transformation
      # @param handler [Battle::Logic::TransformHandler]
      # @param target [PFM::PokemonBattler]
      def on_transform_event(handler, target)
        return unless @pokemon == target

        restore_original_types
        kill
      end

      # TODO : Add a method to check for form changing

      # Restore the original types of the Pokemon
      def restore_original_types
        @pokemon.type1, @pokemon.type2, @pokemon.type3 = @original_type
      end

      # Get the effect name
      # @return [Symbol]
      def name
        :change_type
      end
    end
  end
end
