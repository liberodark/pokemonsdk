module Battle
  module Effects
    # Implement the Out of Reach effect
    class OutOfReachBase < PokemonTiedEffectBase
      include Mechanics::OutOfReach

      # Create a new out reach effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param exceptions [Array<Symbol>] move that hit the target while out of reach
      def initialize(logic, pokemon, exceptions)
        super(logic, pokemon)
        initialize_out_of_reach(pokemon, exceptions)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :out_of_reach_base
      end

      # Function called after damages were applied and when target died (post_damage_death)
      # @param handler [Battle::Logic::DamageHandler]
      # @param hp [Integer] number of hp (damage) dealt
      # @param target [PFM::PokemonBattler]
      # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
      # @param skill [Battle::Move, nil] Potential move used
      def on_post_damage_death(handler, hp, target, launcher, skill)        
        target.effects.get(&:out_of_reach?)&.kill
        target.effects.deleted_dead_effects
      end
    end
  end
end
