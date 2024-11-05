module Battle
  class Move
    # Class that manage the Revival Blessing move
    # @see https://bulbapedia.bulbagarden.net/wiki/Revival_Blessing_(move)
    # @see https://pokemondb.net/move/Revival_Blessing
    # @see https://www.pokepedia.fr/Second_Souffle
    class RevivalBlessing < Move
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        if @logic.all_battlers.none? do |battler|
            next unless battler.bank == user.bank
            next unless battler.party_id == user.party_id

            next battler.dead?
          end
          show_usage_failure(user)
          return false
        end

        return true
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        dead_party = @logic.all_battlers.select do |battler|
          next unless battler.bank == user.bank
          next unless battler.party_id == user.party_id

          next battler.dead?
        end

        if user.from_player_party?
          GamePlay.open_party_menu_to_revive_pokemon(@logic.all_battlers.select(&:from_player_party?))

          target = logic.all_alive_battlers.find do |battler|
            battler.position != -1 && @scene.visual.battler_sprite(battler.bank, battler.position).out?
          end
          summon_revived_ally(target) if target
        else # AI revives its ace
          target = dead_party.max_by(&:level)
          target.hp = target.max_hp / 2
          @scene.display_message_and_wait(parse_text_with_pokemon(66, 1590, target))
          summon_revived_ally(target) if target.position != -1
        end
      end

      private

      # If the target is the ally that just got KO'd in a double battle, it gets directly brought back
      # @param ally [PFM::PokemonBattler] ally revived by the move
      def summon_revived_ally(ally)
        @scene.visual.battler_sprite(ally.bank, ally.position).go_in
        logic.actions.reject! { |a| a.is_a?(Actions::Attack) && a.launcher == ally}
      end
    end
    Move.register(:s_revival_blessing, RevivalBlessing)
  end
end
