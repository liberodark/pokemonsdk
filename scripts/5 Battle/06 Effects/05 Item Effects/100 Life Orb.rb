module Battle
  module Effects
    class Item
      class LifeOrb < Item
        # Create a new Life Orb effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the item
        def initialize(logic, target, db_symbol)
          super

          @activated = false
          @show_message = false
        end

        # Give the move mod1 mutiplier (after the critical)
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def mod2_multiplier(user, target, move)
          return 1.3 if user == @target

          return super
        end

        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return unless can_apply_effect?(target, launcher, skill)

          @activated = true
        end
        alias on_post_damage_death on_post_damage

        # Function called at the end of an action
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?
          return unless @activated
          return if @show_message

          hp = (@target.max_hp / 10).clamp(1, @target.hp)

          logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 1044, @target, PFM::Text::ITEM2[1] => @target.item_name))
          logic.damage_handler.damage_change(hp, @target)
          @show_message = true
        end

        # Function called at the end of a turn
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_end_turn_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if target.dead?
          return unless @activated

          @activated = false
          @show_message = false
        end

        private

        # Check if this the last hit of the move
        # @param skill [Battle::Move, nil] Potential move used
        def last_hit?(skill)
          return true unless skill.is_a?(Battle::Move::Basic::MultiHit)

          # @type [Battle::Move::Basic::MultiHit]
          skill_multi_hit = skill
          return skill_multi_hit.last_hit?
        end

        # Checks if the effect can be applied
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Boolean]
        def can_apply_effect?(target, launcher, skill)
          return false if launcher != @target || launcher == target
          return false if launcher.has_ability?(:magic_guard)
          return false if launcher.has_ability?(:sheer_force) && launcher.ability_effect&.activated?
          return false unless skill || last_hit?(skill)
          return false if @activated

          return true
        end
      end
      register(:life_orb, LifeOrb)
    end
  end
end
