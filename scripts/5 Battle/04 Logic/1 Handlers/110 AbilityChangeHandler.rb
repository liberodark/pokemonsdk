module Battle
  class Logic
    # Handler responsive of answering properly ability changes requests
    class AbilityChangeHandler < ChangeHandlerBase
      include Hooks

      # Lists of abilities that cannot be lost
      CANT_OVERWRITE_ABILITIES = %i[
        as_one battle_bond comatose commander disguise gulp_missile hadron_engine hunger_switch ice_face imposter
        multitype orichalcum_pulse power_construct protosynthesis quark_drive rks_system schooling shields_down
        stance_change wonder_guard zen_mode zero_to_hero
      ]

      # Lists of abilities that cannot be gained
      RECEIVER_CANT_COPY_ABILITIES = %i[
        as_one battle_bond comatose commander disguise flower_gift forecast gulp_missile hadron_engine
        hunger_switch ice_face illusion imposter multitype neutralising_gas orichalcum_pulse poison_puppeteer power_construct power_of_alchemy
        prokosynthesis protosynthesis quark_drive receiver rks_system schooling shields_down stance_change
        trace wonder_guard zen_mode zero_to_hero
      ]

      # Lists of abilities that make these moves fail
      SKILL_BLOCKING_ABILITIES = {
        entrainment: %i[truant],
        simple_beam: %i[simple truant],
        worry_seed: %i[insomnia truant]
      }

      # Function that change the ability of a Pokemon
      # @param target [PFM::PokemonBattler] Target of ability changing
      # @param ability_symbol [Symbol] db_symbol of the ability to give
      # @param launcher [PFM::PokemonBattler, nil] Potentiel launcher of ability changing
      # @param skill [Battle::Move, nil] Potential move used
      def change_ability(target, ability_symbol, launcher = nil, skill = nil)
        target.ability = data_ability(ability_symbol)&.id || 0
        exec_hooks(AbilityChangeHandler, :post_ability_change, binding)
      end

      # Function that tell if this is possible to change the ability of a Pokemon
      # @param target [PFM::PokemonBattler] Target of ability changing
      # @param launcher [PFM::PokemonBattler, nil] Potentiel launcher of ability changing
      # @param skill [Battle::Move, nil] Potential move used
      def can_change_ability?(target, launcher = nil, skill = nil)
        return false if launcher&.battle_ability_db_symbol == :__undef__

        log_data("# can_change_ability?(#{target}, #{launcher}, #{skill})")
        exec_hooks(AbilityChangeHandler, :ability_change_prevention, binding)
        return true
      rescue Hooks::ForceReturn => e
        log_data("# FR: can_change_ability? #{e.data} from #{e.hook_name} (#{e.reason})")
        return e.data
      end

      # Applies the ability change
      # @param target [PFM::PokemonBattler] Target of ability changing
      # @param ability_symbol [Symbol] db_symbol of the ability to give
      # @param launcher [PFM::PokemonBattler] Potentiel launcher of ability changing
      # @param skill [Battle::Move, nil] Potential move used
      # @param message [Proc, nil] Optional message proc for display after ability change
      def apply_ability_change(target, ability_symbol, launcher, skill = nil, &message)
        @scene.visual.show_ability(target)
        @scene.visual.wait_for_animation

        change_ability(target, ability_symbol, launcher, skill)

        @scene.visual.show_ability(target)
        @scene.visual.wait_for_animation
        @scene.display_message_and_wait(message.call) if message

        target.ability_effect.on_switch_event(@logic.switch_handler, target, target) if ability_changed?(target)
      end

      # Applies the ability swap
      # @param user [PFM::PokemonBattler] user of the move
      # @param target [PFM::PokemonBattler] target of the move
      # @param skill [Battle::Move, nil] Potential move used
      def apply_ability_swap(user, target, skill = nil)
        @scene.visual.show_ability(user)
        @scene.visual.show_ability(target)
        @scene.visual.wait_for_animation

        target_battle_ability_db_symbol = target.battle_ability_db_symbol
        change_ability(target, user.battle_ability_db_symbol, user, skill)
        change_ability(user, target_battle_ability_db_symbol, target, skill)

        @scene.visual.show_ability(user)
        @scene.visual.show_ability(target)
        @scene.visual.wait_for_animation
        @scene.display_message_and_wait(parse_text_with_pokemon(19, 508, user))

        user.ability_effect.on_switch_event(@logic.switch_handler, user, user) if ability_changed?(user)
        target.ability_effect.on_switch_event(@logic.switch_handler, target, target) if ability_changed?(target)
      end

      # Checks if the battler's current ability differs from its original ability before the battle
      # @param battler [PFM::PokemonBattler]
      # @return [Boolean]
      def ability_changed?(battler)
        battler.battle_ability_db_symbol != battler.original.ability_db_symbol
      end

      class << self
        # Function that registers a ability_change_prevention hook
        # @param reason [String] reason of the ability_change_prevention registration
        # @yieldparam handler [AbilityChangeHandler]
        # @yieldparam target [PFM::PokemonBattler] Target of ability changing
        # @yieldparam launcher [PFM::PokemonBattler, nil] Potentiel launcher of ability changing
        # @yieldparam skill [Battle::Move, nil] Potential move used
        # @yieldreturn [:prevent, nil] :prevent if the ability cannot be changed
        def register_ability_prevention_hook(reason)
          Hooks.register(AbilityChangeHandler, :ability_change_prevention, reason) do |hook_binding|
            result = yield(
              self,
              hook_binding.local_variable_get(:target),
              hook_binding.local_variable_get(:launcher),
              hook_binding.local_variable_get(:skill)
            )
            force_return(false) if result == :prevent
          end
        end

        # Function that registers a post_ability_change hook
        # @param reason [String] reason of the ability_change_prevention registration
        # @yieldparam handler [AbilityChangeHandler]
        # @yieldparam target [PFM::PokemonBattler] Target of ability changing
        # @yieldparam ability_symbol [Symbol] db_symbol of the ability to give
        # @yieldparam launcher [PFM::PokemonBattler, nil] Potentiel launcher of ability changing
        # @yieldparam skill [Battle::Move, nil] Potential move used
        # @yieldreturn [:prevent, nil] :prevent if the ability cannot be changed
        def register_post_ability_change_hook(reason)
          Hooks.register(AbilityChangeHandler, :post_ability_change, reason) do |hook_binding|
            yield(
              self,
              hook_binding.local_variable_get(:target),
              hook_binding.local_variable_get(:ability_symbol),
              hook_binding.local_variable_get(:launcher),
              hook_binding.local_variable_get(:skill)
            )
          end
        end
      end
    end

    # Check that the receiver of the ability change does not have a ability that is impossible to lose
    AbilityChangeHandler.register_ability_prevention_hook('PSDK Ability Prev: Cannot OW Target Ability') do |handler, target|
      next unless AbilityChangeHandler::CANT_OVERWRITE_ABILITIES.include?(target.battle_ability_db_symbol)

      next handler.prevent_change
    end

    # Check that the giver of the ability change does not have a ability that is impossible to gained
    AbilityChangeHandler.register_ability_prevention_hook('PSDK Ability Prev: Cannot Gained Launcher Ability') do |handler, _, launcher|
      next unless launcher && AbilityChangeHandler::RECEIVER_CANT_COPY_ABILITIES.include?(launcher.battle_ability_db_symbol)

      next handler.prevent_change
    end

    # Check that the receiver of the ability change does not have a ability that is impossible to lose against this skill
    AbilityChangeHandler.register_ability_prevention_hook('PSDK Ability Prev: Cannot OW Target Ability With Skill') do |handler, target, _, skill|
      next unless skill && target && AbilityChangeHandler::SKILL_BLOCKING_ABILITIES[skill.db_symbol]&.include?(target.battle_ability_db_symbol)

      next handler.prevent_change
    end

    AbilityChangeHandler.register_post_ability_change_hook('PSDK Post Ability Change: Illusion reset') do |handler, target|
      next unless target.original.ability_db_symbol == :illusion && target.illusion

      target.illusion = nil
      handler.scene.visual.show_ability(target)
      handler.scene.visual.show_switch_form_animation(target)
      handler.scene.display_message_and_wait(parse_text_with_pokemon(19, 478, target))
    end
  end
end
