module Battle
  class Move
    # Class managing Psychic Noise move
    class PsychicNoise < Basic
      # Ability preventing the move from working
      BLOCKING_ABILITY = %i[aroma_veil]

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        @prevent_effect = false
        actual_targets.each do |target|
          ally = @logic.allies_of(target).find { |a| BLOCKING_ABILITY.include?(a.battle_ability_db_symbol) }
          if user.can_be_lowered_or_canceled?(BLOCKING_ABILITY.include?(target.battle_ability_db_symbol))
            process_prevention(target, target)
          elsif user.can_be_lowered_or_canceled? && ally
            process_prevention(target, ally)
          end

          next if @prevent_effect

          target.effects.add(Effects::HealBlock.new(@logic, target, 3))
          @scene.display_message_and_wait(parse_text_with_pokemon(19, 884, target))
        end
      end

      # Function that does the stuff happening when the effect is unappliable
      # @param target [PFM::PokemonBattler] target of the move/effect
      # @param ability_owner [PFM::PokemonBattler] owner of the ability preventing the effect
      def process_prevention(target, ability_owner)
        @scene.visual.show_ability(ability_owner)
        @scene.display_message_and_wait(parse_text_with_pokemon(19, 1183, target))
        @prevent_effect = true
      end
    end
    Move.register(:s_psychic_noise, PsychicNoise)
  end
end
