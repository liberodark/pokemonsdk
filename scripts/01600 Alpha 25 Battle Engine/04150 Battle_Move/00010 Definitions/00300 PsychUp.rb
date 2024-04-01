module Battle
  class Move
    # Class managing the Psych Up move
    class PsychUp < Move
      # Test if the target is immune
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def target_immune?(user, target)
        return true if target.effects.has?(:crafty_shield)

        return super
      end

      private

      # Check if the move bypass chance of hit and cannot fail
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @return [Boolean]
      def bypass_chance_of_hit?(user, target)
        return true unless target.effects.has?(&:out_of_reach?)

        super
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        user.battle_stage.fill(0)
        actual_targets.each do |target|
          critical_effects_process(user, target)
          target.battle_stage.each_with_index do |value, index|
            next if value == 0

            user.set_stat_stage(index, value)
          end

          @scene.display_message_and_wait(parse_text_with_pokemon(19, 1053, user, PFM::Text::PKNICK[1] => target.given_name))
        end
      end

      # Function that checks the Critical Hit Rate Up effects (e.g. Focus Energy) and copies or clears from user.
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def critical_effects_process(user, target)
        effects = %i[focus_energy dragon_cheer].map! { |e| target.effects.get(e) }
        if effects.none?
          %i[focus_energy dragon_cheer].each { |e| user.effects.get(e)&.kill }
        else
          # The two effects can't coexist, therefore the effects array is always of size = 1
          user.effects.add(effects.first)
        end
      end
    end
    Move.register(:s_psych_up, PsychUp)
  end
end
