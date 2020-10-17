module Battle
  module Effects
    # Class that describe an effect that is tied to a Pokemon
    class PokemonTiedEffectBase < EffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      def initialize(logic, pokemon)
        super(logic)
        @pokemon = pokemon
      end
    end
  end
end
