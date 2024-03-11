module Battle
  module Effects
    class Ability
      class Opportunist < Ability
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
      end
      register(:opportunist, Opportunist)
    end
  end
end
