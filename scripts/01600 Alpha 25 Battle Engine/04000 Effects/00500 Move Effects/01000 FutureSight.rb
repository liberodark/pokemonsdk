module Battle
  module Effects
    class FutureSight < PositionTiedEffectBase
      # Create a new position tied effect
      # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
      # @param bank [Integer] bank where the effect is tied
      # @param position [Integer] position where the effect is tied
      # @param origin [PFM::PokemonBattler]
      # @param countdown [Integer] amount of turn before the effect proc (including the current one)
      # @param move [Battle::Move]
      def initialize(logic, bank, position, origin, countdown, move)
        super(logic, bank, position)
        @origin = origin
        self.counter = countdown
        @move = move
      end

      # Function called when the effect has been deleted from the effects handler
      def on_delete
        return unless (target = find_target)

        @logic.scene.display_message_and_wait(message(target))
        #TODO: Add animation

        hp = @move.damages(@origin, target)
        damage_handler = @logic.damage_handler
        damage_handler.damage_change_with_process(hp, target, @origin, @move) do
          @logic.scene.display_message_and_wait(parse_text(18, 84)) if @move.critical_hit?
          @move.efficent_message(@move.effectiveness, target) if hp > 0
        end
      end

      # Function giving the name of the effect
      # @return [Symbol]
      def name
        :future_sight
      end

      private

      # Find the defintive target
      # @return [PFM::PokemonBattler, nil]
      def find_target
        return affected_pokemon if affected_pokemon.alive?

        proto_move = Battle::Move.new(:__undef__, 1, 1, @logic.scene)
        def proto_move.target
          :user_or_adjacent_ally
        end
        return proto_move.battler_targets(affected_pokemon, @logic).select(&:alive?).first
      end

      # Message displayed when the effect proc
      # @return [String]
      def message(target)
        parse_text_with_pokemon(19, 1086, target)
      end
    end
  end
end
