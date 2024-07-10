module Battle
  module Effects
    class Ability
      class MirrorArmor < Ability
        # Function called when a stat_change is about to be applied
        # @param handler [Battle::Logic::StatChangeHandler]
        # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
        # @param power [Integer] power of the stat change
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [Integer, nil] if integer, it will change the power
        def on_stat_change(handler, stat, power, target, launcher, skill)
          return unless target == @target
          return if launcher == @target && skill&.original_target.empty?
          return unless launcher&.can_be_lowered_or_canceled?
          return if power >= 0

          handler.scene.visual.show_ability(target)
          handler.scene.visual.wait_for_animation

          battlers_affected = skill&.original_target.empty? ? [launcher] : skill.original_target
          battlers_affected.each do |battler|
            next unless battler.can_fight?

            handler.logic.stat_change_handler.stat_change_with_process(stat, power, battler)
          end

          skill.original_target.clear if skill&.original_target

          return 0
        end
      end
      register(:mirror_armor, MirrorArmor)
    end
  end
end
