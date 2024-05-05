module Battle
  module Effects
    class Item
      class OranBerry < Berry
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target
          return if skill && %i[s_pluck].include?(skill.be_method)

          process_effect(target, launcher, skill)
        end

        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?

          process_effect(@target, nil, nil)
        end

        # Function that executes the effect of the berry (for Pluck & Bug Bite)
        # @param force_heal [Boolean] tell if a healing berry should force the heal
        # @param force_execution [Boolean] tell if the execution of the berry has to be forced
        def execute_berry_effect(force_heal: false, force_execution: false)
          define_singleton_method(:hp_rate_trigger) { 1 } if force_heal

          process_effect(@target, nil, nil, force_execution)
        end

        # Function that process the effect of the berry (if possible)
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @param force_execution [Boolean] tell if the execution of the berry has to be forced
        def process_effect(target, launcher, skill, force_execution = false)
          return if target.dead? || target.hp_rate > hp_rate_trigger
          return if cannot_be_consumed?(force_execution)

          @logic.damage_handler.heal(target, hp_healed) do
            item_name = data_item(db_symbol).name
            @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 914, target, PFM::Text::ITEM2[1] => item_name))
          end
          consume_berry(target, launcher, skill, should_confuse: should_confuse)
        end

        # Give the hp rate that triggers the berry
        # @return [Float]
        def hp_rate_trigger
          return 0.5
        end

        # Give the amount of HP healed
        # @return [Integer]
        def hp_healed
          return @target.has_ability?(:ripen) ? 20 : 10
        end

        # Tell if the berry effect should confuse
        # @return [Boolean]
        def should_confuse
          return false
        end
      end

      class SitrusBerry < OranBerry

        # Give the amount of HP healed
        # @return [Integer]
        def hp_healed
          return (@target.max_hp * 2 / 4).clamp(1, Float::INFINITY) if @target.has_ability?(:ripen)

          return (@target.max_hp / 4).clamp(1, Float::INFINITY)
        end
      end

      class BerryJuice < OranBerry
        def hp_healed
          return @target.has_ability?(:ripen) ? 40 : 20
        end
      end

      class ConfusingBerries < OranBerry
        # Give the hp rate that triggers the berry
        # @return [Float]
        def hp_rate_trigger
          return @target.has_ability?(:gluttony) ? 0.5 : 0.25
        end

        # Give the amount of HP healed
        # @return [Integer]
        def hp_healed
          return (@target.max_hp * 2 / 3).clamp(1, Float::INFINITY) if @target.has_ability?(:ripen)

          return (@target.max_hp / 3).clamp(1, Float::INFINITY)
        end

        # Tell if the berry effect should confuse
        # @return [Boolean]
        def should_confuse
          return true
        end
      end
      register(:oran_berry, OranBerry)
      register(:sitrus_berry, SitrusBerry)
      register(:berry_juice, BerryJuice)
      register(:figy_berry, ConfusingBerries)
      register(:wiki_berry, ConfusingBerries)
      register(:mago_berry, ConfusingBerries)
      register(:aguav_berry, ConfusingBerries)
      register(:iapapa_berry, ConfusingBerries)
    end
  end
end
