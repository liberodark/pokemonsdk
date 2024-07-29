module Battle
  class Move
    class BellyDrum < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        stats_changeable = stats.keys.none? { |stat| stat_changeable?(stat, user) }
        if user.hp_rate <= (1.0 / factor) || stats_changeable
          show_usage_failure(user)
          return false
        end

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          next if target.hp_rate <= (1.0 / factor)

          hp = (target.max_hp / factor).floor
          logic.damage_handler.damage_change(hp, target)
          scene.display_message_and_wait(message(user, target)) if message(user, target)

          stats.each { |stat, power| logic.stat_change_handler.stat_change_with_process(stat, power, target, user, self) }
        end
      end

      # Check if a stat is changeable
      # @param stat [Symbol] the stat to check
      # @param user [PFM::PokemonBattler] user of the move
      # @return [Boolean]
      def stat_changeable?(stat, user)
        return true if user.has_ability?(:contrary)

        return logic.stat_change_handler.stat_increasable?(stat, user, user, self)
      end

      # The divisor used to calculate the HP cost
      # @return [Integer]
      def factor
        return 2
      end

      # Method containing stats and the power to raise them
      # @return [Hash<Symbol, Integer>]
      def stats
        return { atk: 12 }
      end

      # Parse a text from the text database with specific informations and a pokemon
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      # @return [String, nil] the text parsed and ready to be displayed
      def message(user, target)
        return parse_text_with_pokemon(19, 613, target)
      end
    end

    class FilletAway < BellyDrum
      # Method containing stats and the power to raise them
      # @return [Hash<Symbol, Integer>]
      def stats
        return { atk: 2, ats: 2, spd: 2 }
      end

      # Parse a text from the text database with specific informations and a pokemon
      # @param user [PFM::PokemonBattler]
      # @param targets [Array<PFM::PokemonBattler>]
      # @return [String, nil] the text parsed and ready to be displayed
      def message(user, target)
        return nil
      end
    end

    Move.register(:s_bellydrum, BellyDrum)
    Move.register(:s_fillet_away, FilletAway)
  end
end
