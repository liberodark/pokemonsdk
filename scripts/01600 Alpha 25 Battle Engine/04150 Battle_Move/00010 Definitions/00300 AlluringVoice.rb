module Battle
  class Move
    class AlluringVoice < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return actual_targets.all? { |target| target.stat_history&.last&.current_turn? && target.stat_history&.last&.power&.positive? }
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next unless target.stat_history&.last&.current_turn?
          next unless target.stat_history&.last&.power&.positive?
          next unless logic.status_change_handler.status_appliable?(status, target, user, self)

          logic.status_change_handler.status_change(status, target, user, self)
        end
      end

      # @return [Symbol] the status that will be applied to the pokemon
      def status
        return :confusion
      end
    end

    class BurningJealousy < AlluringVoice
      # @return [Symbol] the status that will be applied to the pokemon
      def status
        return :burn
      end
    end

    Move.register(:s_alluring_voice, AlluringVoice)
    Move.register(:s_burning_jealousy, BurningJealousy)
  end
end