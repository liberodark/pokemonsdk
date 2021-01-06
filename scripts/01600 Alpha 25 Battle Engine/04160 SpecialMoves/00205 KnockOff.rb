module Battle
  class Move
    # Move that inflict Knock Off to the ennemy
    class KnockOff < Move
      # List of item that cannot be knocked off
      PROTECTED_ITEMS = %i[exp._share lucky_egg amulet_coin oak’s_letter gram_1 gram_2 gram_3 prof’s_letter letter
                           greet_mail favored_mail rsvp_mail thanks_mail inquiry_mail like_mail reply_mail
                           bridge_mail_s bridge_mail_d bridge_mail_t bridge_mail_v bridge_mail_m gengarite
                           gardevoirite ampharosite venusaurite charizardite_x blastoisinite mewtwonite_x mewtwonite_y
                           blazikenite medichamite houndoominite aggronite banettite tyranitarite scizorite pinsirite
                           aerodactylite lucarionite abomasite kangaskhanite gyaradosite absolite charizardite_y alakazite
                           heracronite mawilite manectite garchompite latiasite latiosite swampertite sceptilite sablenite
                           altarianite galladite audinite metagrossite sharpedonite slowbronite steelixite pidgeotite glalitite
                           diancite cameruptite lopunnite salamencite beedrillite red_orb blue_orb jade_orb]
      # List of items that cannot be knocked off if the holder is a specific Pokemon
      PROTECTED_POKEMON_ITEMS = {
        giratina: %i[griseous_orb],
        arceus: %i[flame_plate splash_plate zap_plate meadow_plate icicle_plate fist_plate toxic_plate earth_plate sky_plate mind_plate insect_plate
                   stone_plate spooky_plate draco_plate dread_plate iron_plate pixie_plate],
        genesect: %i[shock_drive burn_drive chill_drive douse_drive]
      }
      # Function that tests if the user is able to use the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @note Thing that prevents the move from being used should be defined by :move_prevention_user Hook
      # @return [Boolean] if the procedure can continue
      def move_usable_by_user(user, targets)
        return false unless super

        if @logic.battler_attacks_last?(user)
          show_usage_failure(user)
          return false
        end

        return true
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        return if user.dead?
        return unless @logic.battle_info.trainer_battle? || user.from_party?

        actual_targets.each do |target|
          next if target.dead? || target.battle_effect.has_substitute_effect?
          next if user.can_be_lowered_or_canceled?(target.ability_db_symbol == :sticky_hold)
          next if target.battle_item_db_symbol == :__undef__ || PROTECTED_ITEMS.include?(target.item_db_symbol)
          next if PROTECTED_POKEMON_ITEMS[target.db_symbol]&.include?(target.battle_item_db_symbol)

          additionnal_variables = {
            PFM::Text::ITEM2[2] => target.item_name,
            PFM::Text::PKNICK[1] => target.given_name
          }
          @scene.display_message(parse_text_with_pokemon(19, 1056, user, additionnal_variables))
          @logic.item_change_handler.change_item(:none, true, target)
        end
      end
    end

    Move.register(:s_knock_off, KnockOff)
  end
end
