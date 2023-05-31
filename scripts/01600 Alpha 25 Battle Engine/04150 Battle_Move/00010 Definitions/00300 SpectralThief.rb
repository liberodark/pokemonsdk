module Battle
  class Move
    class SpectralThief < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return actual_targets.any? { |target| target.battle_stage.any?(&:positive?) }
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless target.battle_stage.any?(&:positive?)

          target.battle_stage.each_with_index do |stat_value, index|
            next unless stat_value.positive?

            user.set_stat_stage(index, stat_value)
            target.set_stat_stage(index, 0)
          end
          @scene.display_message_and_wait(parse_text_with_pokemon(59, 1934, user))
        end
      end
    end
    Move.register(:s_spectral_thief, SpectralThief)
  end
end
