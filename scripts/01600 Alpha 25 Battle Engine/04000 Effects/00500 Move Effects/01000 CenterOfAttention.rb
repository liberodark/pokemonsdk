module Battle
  module Effects
    class CenterOfAttention < PokemonTiedEffectBase
      # The move that caused this effect
      # @return [Symbol]
      attr_reader :origin_move

      # Moves that ignore this effect
      MOVES_IGNORING_THIS_EFFECT = %i[snipe_shot]

      # Create a new Center of Attention effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param turn_count [Integer] amount of turn the effect is active
      # @param origin_move [Battle::Move] the move that caused this effect
      def initialize(logic, pokemon, turn_count, origin_move)
        super(logic, pokemon)
        self.counter = turn_count
        @origin_move = origin_move
      end

      # Return the new target if the conditions are fulfilled
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @param move [Battle::Move]
      # @return [PFM::PokemonBattler] the new target if the conditions are fulfilled, the initial target otherwise
      def target_redirection(user, targets, move)
        return if user&.ability_effect&.ignore_target_redirection?
        return if MOVES_IGNORING_THIS_EFFECT.include?(move.db_symbol) || move.two_turn?
        return if @origin_move.db_symbol == :rage_powder && rage_powder_immunity?(user)
        return if @pokemon.effects.has?(:prevent_targets_move)

        return @pokemon
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        return :center_of_attention
      end

      private

      # Check if the user of the move has an immunity to powders moves
      # @param user [PFM::PokemonBattler] user of the move
      # @return [Boolean]
      def rage_powder_immunity?(user)
        return true if user.has_ability?(:overcoat)
        return true if user.hold_item?(:safety_goggles)
        return true if user.type_grass?

        return false
      end
    end
  end
end
