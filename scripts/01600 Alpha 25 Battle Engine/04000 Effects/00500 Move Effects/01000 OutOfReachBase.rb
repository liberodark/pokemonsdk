module Battle
  module Effects
    # Implement the Out of Reach effect
    class OutOfReachBase < PokemonTiedEffectBase
      include Mechanics::OutOfReach

      # Create a new out reach effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @param exceptions [Array<Symbol>] move that hit the target while out of reach
      # @param turncount [Integer] (default: 5) number of turn the effect proc (including the current one)
      def initialize(logic, pokemon, move, exceptions, turncount = 2)
        super(logic, pokemon)
        initialize_out_of_reach(pokemon, move, exceptions, turncount)
        logic.scene.visual.battler_sprite(pokemon.bank, pokemon.position).opacity = 0
      end

      # Function called when the effect has been deleted from the effects handler
      def on_delete
        return @logic.scene.visual.battler_sprite(@pokemon.bank, @pokemon.position).opacity = 255
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :out_of_reach_base
      end
    end
  end
end
