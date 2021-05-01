module Battle
  module Effects
    # Implement the Lock-On and Mind Reader effect
    class LockOn < PokemonTiedEffectBase
      # The Pokemon that launched the attack
      # @return [PFM::PokemonBattler]
      attr_reader :origin

      # Create a new Pokemon Lock-On effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param user [PFM::PokemonBattler]
      def initialize(logic, target, user)
        super(logic, target)
        @origin = user
        self.counter = 2
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :lock_on
      end
    end
  end
end
