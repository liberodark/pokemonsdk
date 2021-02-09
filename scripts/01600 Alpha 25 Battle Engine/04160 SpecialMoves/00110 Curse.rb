module Battle
  class Move
    # Class managing Curse
    class Curse < Move
      # Function that deals the stat to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_stats(user, actual_targets)
        return false if user.type_ghost?

        @logic.stat_change_handler.stat_change_with_process(:spd, -1, user, user, self)
        @logic.stat_change_handler.stat_change_with_process(:atk, 1, user, user, self)
        @logic.stat_change_handler.stat_change_with_process(:dfe, 1, user, user, self)
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        return false unless user.type_ghost?

        actual_targets.each do |target|
          recoil(user.max_hp, user)
          target.effects.add(Effects::Curse.new(@logic, target))
          scene.display_message_and_wait(parse_text_with_pokemon(19, 1070, user,
                                                                 '[VAR PKNICK(0000)]' => user.given_name,
                                                                 '[VAR PKNICK(0001)]' => target.given_name))
        end
      end

      def recoil_factor
        return 2
      end
    end

    Move.register(:s_curse, Curse)
  end
end
