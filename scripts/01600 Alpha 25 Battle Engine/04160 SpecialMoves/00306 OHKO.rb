module Battle
  class Move
    # Class managing OHKO moves
    class OHKO < Basic
      private

      # Test if the target is immune
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def target_immune?(user, target)
        return true if target.type_ice? && db_symbol == :sheer_cold # Immunity after 7G

        return super
      end

      # Return the chance of hit of the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Float]
      def chance_of_hit(user, target)
        log_data("# OHKO move: chance_of_hit(#{user}, #{target}) for #{db_symbol}")
        return 100 if target.effects.get(:lock_on)&.user == user

        return (user.level < target.level ? 0 : (user.level - target.level) + 30)
      end

      # Method calculating the damages done by the actual move
      # @note : I used the 4th Gen formula : https://www.smogon.com/dp/articles/damage_formula
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @param rng [Random] random generator used for the move
      # @return [Integer]
      def damages(user, target, rng)
        @critical = false
        @effectiveness = 1
        log_data('OHKO Move: 100% HP')
        return target.max_hp
      end

      def ohko?
        return true
      end
    end

    Move.register(:s_ohko, OHKO)
  end
end
