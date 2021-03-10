module Battle
  class Move
    # class managing HappyHour move
    class HappyHour < Move
      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(_user, _actual_targets)
        logic.terrain_effects.add(Effects::HappyHour.new(logic)) unless logic.terrain_effects.has?(:happy_hour)
        scene.display_message_and_wait(parse_text(18, 255))
      end
    end

    Move.register(:s_happy_hour, HappyHour)
  end
end
