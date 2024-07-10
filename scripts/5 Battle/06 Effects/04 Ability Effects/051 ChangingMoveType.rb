module Battle
  module Effects
    class Ability
      class ChangingMoveType < BoostingMoveType
        # List of type overwrite
        TYPES_OVERWRITES = Hash.new(:normal)

        # Function called when we try to get the definitive type of a move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @param type [Integer] current type of the move (potentially after effects)
        # @return [Integer, nil] new type of the move
        def on_move_type_change(user, target, move, type)
          return nil if self.target != user || move.be_method == :s_weather_ball || type != data_type(:normal).id

          return data_type(TYPES_OVERWRITES[db_symbol]).id
        end

        class << self
          # Register a ChangingMoveType ability
          # @param db_symbol [Symbol] db_symbol of the ability
          # @param type_overwrite [Symbol] move type overwrite for weather_ball
          # @param multiplier [Float] multiplier if all condition are meet
          # @param block [Proc] additional condition
          # @yieldparam user [PFM::PokemonBattler]
          # @yieldparam target [PFM::PokemonBattler]
          # @yieldparam move [Battle::Move]
          # @yieldreturn [Boolean]
          def register(db_symbol, type_overwrite, multiplier = 1.3, &block)
            POWER_INCREASE_CONDITION[db_symbol] = block if block
            BoostingMoveType::TYPE_CONDITION[db_symbol] = :normal
            TYPES_OVERWRITES[db_symbol] = type_overwrite
            BoostingMoveType::POWER_INCREASE[db_symbol] = multiplier if multiplier
            Ability.register(db_symbol, ChangingMoveType)
          end
        end

        register(:pixilate, :fairy)
        register(:refrigerate, :ice)
        register(:aerilate, :flying)
        register(:galvanize, :electric)
      end
    end
  end
end
