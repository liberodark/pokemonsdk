module Battle
  module Effects
    class Charge < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param turncount [Integer] amount of turn the effect is active
      def initialize(logic, pokemon, turncount)
        super(logic, pokemon)
        self.counter = turncount
      end

      # Name of the effect
      # @return [Symbol]
      def name
        :charge
      end

      # Modify the power of a move when the effect owner is the user
      # @param power [Integer]
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @param move [Battle::Move]
      # @return [Integer] modifed power
      def calc_base_power_as_user(power, user, target, move)
        return power * (move.type_electric? ? 2 : 1)
      end
    end
  end
end