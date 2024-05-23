module Battle
  module Effects
    class Ability
      class MentalImmunityBase < Ability
        # List of mental effects
        # @return [Array<Symbol>]
        MENTAL_EFFECTS = %i[attract encore taunt torment heal_block disable]

        # Function called when we try to check if the Pokemon is immune to a move due to its effect
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Boolean] if the target is immune to the move
        def on_move_ability_immunity(user, target, move)
          return false unless target == @target
          return false unless move.mental?
          return false unless user.can_be_lowered_or_canceled?

          move.scene.visual.show_ability(@target)

          return true
        end
      end

      class Oblivious < MentalImmunityBase
        # Function called at the end of an action
        # @param logic [Battle::Logic] logic of the battle
        # @param scene [Battle::Scene] battle scene
        # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
        def on_post_action_event(logic, scene, battlers)
          return unless battlers.include?(@target)
          return if @target.dead?
          return if MENTAL_EFFECTS.none? { |effect| @target.effects.has?(effect) }

          scene.visual.show_ability(@target)
          scene.visual.wait_for_animation
          MENTAL_EFFECTS.each { |effect| @target.effects.get(effect)&.kill }
        end
      end

      class AromaVeil < MentalImmunityBase
        # Create a Aroma Veil effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @affect_allies = true
        end
      end

      register(:oblivious, Oblivious)
      register(:aroma_veil, AromaVeil)
    end
  end
end
