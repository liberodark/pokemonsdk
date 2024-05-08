module Battle
  module Effects
    class Ability
      class Levitate < Ability
        # Create a new Levitate effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        # @note Used to track the last launcher & if they have mold breaker
        def initialize(logic, target, db_symbol)
          super
          @last_launcher = nil
          @mb_launcher = nil
        end

        # Function called when we try to check if the target has an immunity due to the type of move & ability
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Boolean] if the target is immune to the move
        def on_move_ability_immunity(user, target, move)
          @last_launcher = user
          @mb_launcher = user if user.has_ability?(:mold_breaker)
          move.scene.visual.show_ability(target) if move.type_ground? && !user.has_ability?(:mold_breaker)
          return false if user.can_be_lowered_or_canceled? || user.has_ability?(:mold_breaker)

          move.scene.visual.show_ability(target)
          return true
        end

        # Function that computes an overwrite of the type multiplier
        # @param target [PFM::PokemonBattler]
        # @param target_type [Integer] one of the type of the target
        # @param type [Integer] one of the type of the move
        # @param move [Battle::Move]
        # @return [Float, nil] overwriten type multiplier
        def on_single_type_multiplier_overwrite(target, target_type, type, move)
          return unless target == @target
          return if target == @mb_launcher
          return unless @last_launcher == @mb_launcher && @last_launcher != nil

          return data_type(type).hit(data_type(target_type).db_symbol)
        end
      end
      register(:levitate, Levitate)
    end
  end
end
