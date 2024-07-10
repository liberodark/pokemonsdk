module Battle
  class Move
    # Parting Shot lowers the opponent's Attack and Special Attack by one stage each, then the user switches out of battle.
    # @see https://pokemondb.net/move/parting-shot
    # @see https://bulbapedia.bulbagarden.net/wiki/Parting_Shot_(move)
    # @see https://www.pokepedia.fr/Dernier_Mot
    class PartingShot < Move
      # Tell if the move is a move that switch the user if that hit
      def self_user_switch?
        return true
      end

      private

      # Function that deals the stat to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_stats(user, actual_targets)
        @switchable = switchable?(actual_targets)
        super
      end

      # Function that if the Pokemon can be switched or not
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def switchable?(actual_targets)
        return false unless actual_targets.any? do |target|
          next !target.has_ability?(:contrary) && battle_stage_mod.any? { |stage| logic.stat_change_handler.stat_decreasable?(stage.stat, target) } ||
               target.has_ability?(:contrary) && battle_stage_mod.any? { |stage| logic.stat_change_handler.stat_increasable?(stage.stat, target) }
        end
        return false if actual_targets.all? { |target| target.has_ability?(:clear_body) }
        return false if actual_targets.all? { |target| logic.bank_effects[target.bank].has?(:mist) }

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        return false unless @logic.switch_handler.can_switch?(user, self)
        return false unless @switchable

        @logic.switch_request << { who: user }
      end
    end
    Move.register(:s_parting_shot, PartingShot)
  end
end
