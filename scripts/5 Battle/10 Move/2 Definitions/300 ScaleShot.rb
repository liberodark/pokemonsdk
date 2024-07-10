module Battle
  class Move
    # Inflicts Scale Shot to an enemy (multi hit + drops the defense and rises the speed of the user by 1 stage each)
    class ScaleShot < MultiHit

      private
      # Function that defines the number of hits
      def hit_amount(user, actual_targets)
        return 5 if user.has_ability?(:skill_link)

        return MULTI_HIT_CHANCES.sample(random: @logic.generic_rng)
      end

      # Function that deals the stat to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_stats(user, actual_targets)
        super(user, [user])
      end
    end
    Move.register(:s_scale_shot, ScaleShot)
  end
end
