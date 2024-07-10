module Battle
  module Effects
    class Ability
      class Opportunist < Ability
        COPIED_EFFECTS = {
          focus_energy: {effect_class: Effects::FocusEnergy, text_id: 1047},
          dragon_cheer: {effect_class: Effects::DragonCheer, text_id: 1047} # TODO Change to proper text
        }

        # Create a new Opportunist effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @activated = false
        end

        # @return [Boolean] if the ability is currently activated
        def activated?
          return @activated
        end

        # Function called when a stat_change has been applied
        # @param handler [Battle::Logic::StatChangeHandler]
        # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
        # @param power [Integer] power of the stat change
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Integer, nil] if integer, it will change the power
        def on_stat_change_post(handler, stat, power, target, launcher, skill)
          return unless @logic.foes_of(@target).include?(target)
          return if power <= 0
          return if target.has_ability?(:opportunist) && target.ability_effect.activated?

          @activated = true
          handler.scene.visual.show_ability(@target)
          handler.logic.stat_change_handler.stat_change_with_process(stat, power, @target)
          @activated = false
        end

        # Function called at the end of an action
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?
          return if COPIED_EFFECTS.keys.any? { |effect| @target.effects.has?(effect) }

          # Makde sure the move is used by an opponent
          return unless (move = logic.current_action&.move) && COPIED_EFFECTS.keys.include?(move.db_symbol)
          return unless logic.foes_of(@target).include?(logic.current_action.launcher)
          # Opportunist shall not trigger from an opponent's Opportunist
          return if logic.current_action.launcher.has_ability?(:opportunist) && logic.current_action.launcher.ability_effect.activated?

          @activated = true
          scene.visual.show_ability(@target)
          scene.display_message_and_wait(parse_text_with_pokemon(19, COPIED_EFFECTS[move.db_symbol][:text_id], @target))
          @target.effects.add(COPIED_EFFECTS[move.db_symbol][:effect_class].new(logic, @target))
          @activated = false
        end
      end
      register(:opportunist, Opportunist)
    end
  end
end
