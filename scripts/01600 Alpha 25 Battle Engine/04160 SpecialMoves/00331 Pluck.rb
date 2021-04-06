module Battle
  class Move
    # Class managing the Pluck move
    class Pluck < Basic
      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        return if user.dead?

        actual_targets.each do |target|
          imisc = GameData::Item[target.item_hold].misc_data
          next unless @logic.item_change_handler.can_lose_item?(target, user)
          next unless imisc&.berry

          @scene.display_message_and_wait(parse_text_with_pokemon(19, 776, user, PFM::Text::ITEM2[1] => target.item_name))
          # TODO: Add a method to use berry on the launcher.
          @logic.item_change_handler.change_item(:none, true, target, user, self)
        end
      end
    end
    Move.register(:s_pluck, Pluck)
  end
end
