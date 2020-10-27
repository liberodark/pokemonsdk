module Battle
  class Move
    # Class describing a move hiting multiple time
    class MultiHit < Basic
      MULTI_HIT_CHANCES = [2, 2, 2, 3, 3, 5, 4, 3]
      # Function that deals the damage to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_damage(user, actual_targets)
        nb_hit = hit_amount(user, actual_targets).times.count do
          next false unless actual_targets.all?(&:alive?)

          super
          next true
        end
        @scene.display_message(parse_text(18, 33, PFM::Text::NUMB[1] => nb_hit.to_s))
      end

      private

      # Get the number of hit the move can perform
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Integer]
      def hit_amount(user, actual_targets)
        return 3 if db_symbol == :triple_kick
        return 5 if user.ability_db_symbol == :skill_link

        return MULTI_HIT_CHANCES.sample
      end
    end

    # Class describing a move hiting twice
    class TwoHit < MultiHit
      private

      # Get the number of hit the move can perform
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Integer]
      def hit_amount(user, actual_targets)
        return 2
      end
    end

    Move.register(:s_multi_hit, MultiHit)
    Move.register(:s_2hits, TwoHit)
  end
end
