module Battle
  class Move
    # Class managing TidyUp move
    class TidyUp < BasicWithSuccessfulEffect
      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        logic.all_alive_battlers.each do |b|
          b.effects.each { |e| e.kill if e.rapid_spin_affected? || e.name == :substitute }
          logic.bank_effects[b.bank].each { |e| e.kill if e.rapid_spin_affected? }
        end
      end
    end

    Move.register(:s_tidy_up, TidyUp)
  end
end
