module Battle
  module Effects
    class Ability
      class SheerForce < Ability
        # If the talent is activated or not
        # @return [Boolean]
        attr_writer :activated

        # Create a new PowerSpot effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @activated = false
        end

        # List of the db_symbol of the moves for which their effect is not disabled by Sheer Force
        # @return [Array<Symbol>]
        EXCLUDED_DB_SYMBOLS = %i[thousand_waves fling scale_shot]

        # Return the constant listing the db_symbol of the moves for which their effect are not disabled by Sheer Force
        # @return [Array<Symbol>]
        def excluded_db_symbol
          return EXCLUDED_DB_SYMBOLS
        end

        # List of the be_method of the moves for which their effect is not disabled by Sheer Force
        # @return [Array<Symbol>]
        EXCLUDED_METHODS = %i[s_bind s_reload]

        # Return the constant listing the be_method of the moves for which their effect is not disabled by Sheer Force
        # @return [Array<Symbol>]
        def excluded_methods
          return EXCLUDED_METHODS
        end

        # If Sheer Force is currently activated
        # @return [Boolean]
        def activated?
          return @activated
        end
        alias activated activated?

        # Return the specific proceed_internal if the condition is fulfilled
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>]
        # @param move [Battle::Move]
        def specific_proceed_internal(user, targets, move)
          return :proceed_internal_sheer_force unless excluded?(move)
        end

        # Get the name of the effect
        # @return [Symbol]
        def name
          return :sheer_force
        end

        # Check if a move must have his effect ignored
        # @param move [Battle::Move]
        # @return [Boolean]
        def excluded?(move)
          return false if EXCLUDED_DB_SYMBOLS.include?(move.db_symbol) || EXCLUDED_METHODS.include?(move.be_method)
          return true if move.status? || (move.battle_stage_mod.none? && move.status_effects.none? && move.method("deal_effect").owner == Battle::Move)

          return false
        end

        # Function called when a status_prevention is checked
        # @param handler [Battle::Logic::StatusChangeHandler]
        # @param status [Symbol] :poison, :toxic, :confusion, :sleep, :freeze, :paralysis, :burn, :flinch, :cure
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the status cannot be applied
        def on_status_prevention(handler, status, target, launcher, skill)
          if target != @target && skill && @activated
            return if EXCLUDED_DB_SYMBOLS.include?(skill.db_symbol) || EXCLUDED_METHODS.include?(skill.be_method)

            return handler.prevent_change
          end

          return nil
        end

        # Function called when a stat_increase_prevention is checked
        # @param handler [Battle::Logic::StatChangeHandler] handler use to test prevention
        # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the stat increase cannot apply
        def on_stat_increase_prevention(handler, stat, target, launcher, skill)
          if target == @target && skill && @activated
            return if EXCLUDED_DB_SYMBOLS.include?(skill.db_symbol) || EXCLUDED_METHODS.include?(skill.be_method)

            return handler.prevent_change
          end

          return nil
        end

        # Function called when a stat_decrease_prevention is checked
        # @param handler [Battle::Logic::StatChangeHandler] handler use to test prevention
        # @param stat [Symbol] :atk, :dfe, :spd, :ats, :dfs, :acc, :eva
        # @param target [PFM::PokemonBattler]
        # @param launcher [PFM::PokemonBattler, nil] Potential launcher of a move
        # @param skill [Battle::Move, nil] Potential move used
        # @return [:prevent, nil] :prevent if the stat decrease cannot apply
        def on_stat_decrease_prevention(handler, stat, target, launcher, skill)
          if target != @target && skill && @activated
            return if EXCLUDED_DB_SYMBOLS.include?(skill.db_symbol) || EXCLUDED_METHODS.include?(skill.be_method)

            return handler.prevent_change
          end

          return nil
        end

        # Give the move base power mutiplier
        # @param user [PFM::PokemonBattler] user of the move
        # @param target [PFM::PokemonBattler] target of the move
        # @param move [Battle::Move] move
        # @return [Float, Integer] multiplier
        def base_power_multiplier(user, target, move)
          return 1 unless @activated

          return 1.3
        end
      end
      register(:sheer_force, SheerForce)
    end
  end
end
