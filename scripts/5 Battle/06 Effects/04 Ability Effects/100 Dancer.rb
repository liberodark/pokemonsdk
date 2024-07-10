module Battle
  module Effects
    class Ability
      class Dancer < Ability
        # If the talent is activated or not
        # @return [Boolean]
        attr_writer :activated

        # Create a new Dancer effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @activated = false
        end

        # Return the specific proceed_internal if the condition is fulfilled
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>]
        # @param move [Battle::Move]
        def specific_proceed_internal(user, targets, move)
          return :proceed_internal_dancer if @activated
        end

        # If Dancer is currently activated
        # @return [Boolean]
        def activated?
          return @activated
        end
        alias activated activated?
      end
      register(:dancer, Dancer)
    end
  end
end