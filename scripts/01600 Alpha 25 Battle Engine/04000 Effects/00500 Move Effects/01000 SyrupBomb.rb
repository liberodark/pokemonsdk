module Battle
  module Effects
    # Implement the Syrup Bomb effect
    class SyrupBomb < PokemonTiedEffectBase
      # Create a new effect
      # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
      # @param pokemon [PFM::PokemonBattler] target that will be affected by the effect
      # @param turn_count [Integer] number of turn before the effect proc (including the current one)
      # @param origin [PFM::PokemonBattler] battler that created the effect
      def initialize(logic, pokemon, turn_count, origin)
        super(logic, pokemon)
        @origin = origin
        @pokemon = pokemon
        self.counter = turn_count
      end

      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        return unless battlers.include?(@pokemon)
        return kill if @pokemon.dead?

        logic.stat_change_handler.stat_change_with_process(:spd, -1, @pokemon, @origin)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :syrup_bomb
      end
    end
  end
end
