module Battle
  class Move
    class PlasmaFists < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return !@logic.terrain_effects.has?(:ion_deluge)
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        @logic.terrain_effects.add(Effects::IonDeluge.new(@scene.logic))
        @scene.display_message_and_wait(parse_text(18, 257))
      end
    end
    Move.register(:s_plasma_fists, PlasmaFists)
  end
end
