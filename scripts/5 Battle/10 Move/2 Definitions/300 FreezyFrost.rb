module Battle
  class Move
    class FreezyFrost < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return @logic.all_alive_battlers.each { |battler| battler.battle_stage.any? { |stage| stage != 0 } }
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        @logic.all_alive_battlers.each do |battler|
          next if battler.battle_stage.all?(&:zero?)

          battler.battle_stage.map! { 0 }
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 195, battler))
        end
      end
    end
    Move.register(:s_freezy_frost, FreezyFrost)
  end
end
