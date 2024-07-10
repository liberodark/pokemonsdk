module Battle
  module Effects
    class Ability
      class BoostingMoveType < Ability
        # Initial condition to give the power increase
        POWER_INCREASE_CONDITION = Hash.new(proc { true })
        # Type condition to give the power increase
        TYPE_CONDITION = Hash.new(:normal)
        # Power increase if all condition are met
        POWER_INCREASE = Hash.new(1.5)

        # Get the base power multiplier of this move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Float]
        def base_power_multiplier(user, target, move)
          return 1 if user != @target
          return 1 unless POWER_INCREASE_CONDITION[@db_symbol].call(user, target, move)
          return 1 if move.type != data_type(TYPE_CONDITION[@db_symbol]).id

          return POWER_INCREASE[@db_symbol]
        end

        class << self
          # Register a BoostingMoveType ability
          # @param db_symbol [Symbol] db_symbol of the ability
          # @param type [Symbol] move type getting power increase
          # @param multiplier [Float] multiplier if all condition are meet
          # @param block [Proc] additional condition
          # @yieldparam user [PFM::PokemonBattler]
          # @yieldparam target [PFM::PokemonBattler]
          # @yieldparam move [Battle::Move]
          # @yieldreturn [Boolean]
          def register(db_symbol, type, multiplier = nil, &block)
            POWER_INCREASE_CONDITION[db_symbol] = block if block
            TYPE_CONDITION[db_symbol] = type
            POWER_INCREASE[db_symbol] = multiplier if multiplier
            Ability.register(db_symbol, BoostingMoveType)
          end
        end

        register(:blaze, :fire) { |user| user.hp_rate <= 0.333 }
        register(:overgrow, :grass) { |user| user.hp_rate <= 0.333 }
        register(:torrent, :water) { |user| user.hp_rate <= 0.333 }
        register(:swarm, :bug) { |user| user.hp_rate <= 0.333 }
        register(:dragon_s_maw, :dragon)
        register(:steelworker, :steel)
        register(:transistor, :electric)
        register(:rocky_payload, :rock)
      end
    end
  end
end
