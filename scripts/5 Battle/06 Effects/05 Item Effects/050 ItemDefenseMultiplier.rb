module Battle
  module Effects
    class Item
      class DefenseMultiplier < Item
        # List of conditions to yield the defense multiplier
        CONDITIONS = {}
        # List of multiplier if conditions are met
        MULTIPLIERS = Hash.new(1.5)
        # Give the move [Spe]def mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def sp_def_multiplier(user, target, move)
          return 1 if target != @target
          return 1 unless CONDITIONS[db_symbol].call(user, target, move)

          return MULTIPLIERS[db_symbol]
        end

        class << self
          # Register an item with defense multiplier only
          # @param db_symbol [Symbol] db_symbol of the item
          # @param multiplier [Float] multiplier if condition met
          # @param klass [Class<DefenseMultiplier>] klass to instanciate
          # @param block [Proc] condition to verify
          # @yieldparam user [PFM::PokemonBattler] user of the move
          # @yieldparam target [PFM::PokemonBattler] target of the move
          # @yieldparam move [Battle::Move] move
          # @yieldreturn [Boolean]
          def register(db_symbol, multiplier = nil, klass = DefenseMultiplier, &block)
            Item.register(db_symbol, klass)
            CONDITIONS[db_symbol] = block
            MULTIPLIERS[db_symbol] = multiplier if multiplier
          end
        end
      end
    end
  end
end
