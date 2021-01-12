module Battle
  module Effects
    # Implementation of Leech Seed effect
    # This classs drains the target hp to the Pokemon in the position of its user
    class LeechSeed < PositionTiedEffectBase
      # Create a new position LeechSeed effect
      # @param logic [Battle::Logic] logic used to get all the handler in order to allow the effect to work
      # @param user [PFM::PokemonBattler] receiver of that effect
      # @param target [PFM::PokemonBattler] pokemon getting the damages
      def initialize(logic, user, target)
        super(logic, user.bank, user.position)
        @target = target
        target.effects.add(Mark.new(logic, self))
      end

      # Tell if the effect is dead
      # @return [Boolean]
      def dead?
        super || !@target.position || @target.dead?
      end

      # Function called at the end of a turn
      # @param logic [Battle::Logic] logic of the battle
      # @param scene [Battle::Scene] battle scene
      # @param battlers [Array<PFM::PokemonBattler>] all alive battlers
      def on_end_turn_event(logic, scene, battlers)
        return unless (user = affected_pokemon)
        return if dead?
        return if @target.ability_db_symbol == :magic_guard

        scene.display_message_and_wait(parse_text_with_pokemon(19, 610, @target))
        # TODO: Add an animation
        logic.damage_handler.drain(8, @target, user)
      end

      # Get the name of the effect
      # @return [Symbol]
      def name
        :leech_seed
      end

      # Class marking the target of the LeechSeed so we cannot apply the effect twice
      class Mark < EffectBase
        # Create a new mark
        # @param logic [Battle::Logic]
        # @param origin [LeechSeed] origin of the mark
        def initialize(logic, origin)
          super(logic)
          @origin = origin
        end

        # Tell if the effect is dead
        # @return [Boolean]
        def dead?
          super || @origin.dead?
        end

        # Get the name of the effect
        # @return [Symbol]
        def name
          :leech_seed_mark
        end
      end
    end
  end
end
