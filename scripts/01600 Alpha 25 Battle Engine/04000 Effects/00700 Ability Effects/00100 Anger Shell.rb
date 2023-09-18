module Battle
  module Effects
    class Ability
      class AngerShell < Ability
        # Stats affected by ability activation
        STATS = {atk: 1, ats: 1, spd: 1, dfe: -1, dfs: -1}
        # Function called after damages were applied (post_damage, when target is still alive)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage(handler, hp, target, launcher, skill)
          return if target != @target || launcher == target || target.hp_rate > 0.5
          return if launcher.has_ability?(:sheer_force) && launcher.ability_effect&.activated?
          return unless target.hp + hp > target.max_hp / 2

          handler.scene.visual.show_ability(target)
          handler.scene.visual.wait_for_animation

          STATS.each do |stat, value|
            next if value.positive? && !handler.logic.stat_change_handler.stat_increasable?(stat, target)
            next if value.negative? && !handler.logic.stat_change_handler.stat_decreasable?(stat, target)

            handler.logic.stat_change_handler.stat_change(stat, value, target)
          end
        end
      end
      register(:anger_shell, AngerShell)
    end
  end
end