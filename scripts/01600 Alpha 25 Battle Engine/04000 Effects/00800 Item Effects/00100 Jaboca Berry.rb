module Battle
  module Effects
    class Item
      class JabocaBerry < Berry
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target
          return unless trigger?(skill) && launcher

          process_effect(target, launcher, skill)
        end

        # Function that executes the effect of the berry (for Pluck & Bug Bite)
        # @param force_heal [Boolean] tell if a healing berry should force the heal
        # @param force_execution [Boolean] tell if the execution of the berry has to be forced
        def execute_berry_effect(force_heal: false, force_execution: false)
          process_effect(@target, nil, nil, force_execution)
        end

        private

        # Function that process the effect of the berry (if possible)
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @param force_execution [Boolean] tell if the execution of the berry has to be forced
        def process_effect(target, launcher, skill, force_execution = false)
          return if target.dead?
          return if cannot_be_consumed?(force_execution)

          consume_berry(target, launcher, skill)
          return unless launcher && skill

          @logic.damage_handler.damage_change((launcher.max_hp / 8).clamp(1, Float::INFINITY), launcher)
          @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 402, launcher))
        end

        # Tell if the berry triggers
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Boolean]
        def trigger?(skill)
          skill&.physical?
        end
      end

      class RowapBerry < JabocaBerry
        # Tell if the berry triggers
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Boolean]
        def trigger?(skill)
          skill&.special?
        end
      end
      register(:jaboca_berry, JabocaBerry)
      register(:rowap_berry, RowapBerry)
    end
  end
end
