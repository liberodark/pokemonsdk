module Battle
  module Effects
    # Implement the Lock-On effect
    class LockOn < PokemonTiedEffectBase
      # Create a new Pokemon Lock-On effect
      # @param logic [Battle::Logic]
      # @param target [PFM::PokemonBattler]
      # @param user [PFM::PokemonBattler]
      def initialize(logic, target, user)
        super(logic, target, user)
        @lock_on_user = user
      end

      def lock_on_user
        return @lock_on_user
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :lock_on
      end
    end
  end
end
