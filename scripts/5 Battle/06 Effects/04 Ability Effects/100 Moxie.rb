module Battle
  module Effects
    class Ability
      class Moxie < Ability
        # Create a new Moxie effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @skill_fell_stinger = false
        end

        # Function called after damages were applied and when target died (post_damage_death)
        # @param handler [Battle::Logic::DamageHandler]
        # @param hp [Integer] number of hp (damage) dealt
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        def on_post_damage_death(handler, hp, target, launcher, skill)
          return if launcher != @target || launcher == target
          return (@skill_fell_stinger = true) if skill&.be_method == :s_fell_stinger && !@skill_fell_stinger 
          return unless launcher.alive? && handler.logic.stat_change_handler.stat_increasable?(boosted_stat, launcher)

          handler.scene.visual.show_ability(launcher)
          handler.scene.visual.wait_for_animation
          handler.logic.stat_change_handler.stat_change(boosted_stat, 1, launcher)

          @skill_fell_stinger = false if @skill_fell_stinger
        end

        # The stat that will be boosted
        def boosted_stat
          return :atk
        end
      end

      class GrimNeigh < Moxie
        # The stat that will be boosted
        def boosted_stat
          return :ats
        end
      end
      register(:moxie, Moxie)
      register(:chilling_neigh, Moxie)
      register(:grim_neigh, GrimNeigh)
    end
  end
end