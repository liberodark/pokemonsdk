module Battle
  module Effects
    module Mechanics
      # Give functions to manage a move that force the next one. Must be used in a EffectBase child class.
      module ForceNextMove
        # Get the move the Pokemon has to use
        # @return [Battle::Move]
        attr_reader :move
        # Get the targets of the move
        # @return [Array<PFM::PokemonBattler>]
        attr_reader :targets

        # Function called when we try to use a move as the user (returns :prevent if user fails)
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>]
        # @param move [Battle::Move]
        # @return [:prevent, nil] :prevent if the move cannot continue
        def on_move_prevention_user(user, targets, move)
          return if user != @pokemon
          return if move.db_symbol == @move.db_symbol

          move.show_usage_failure(user)
          return :prevent
        end

        # Tell if the effect forces the next move
        # @return [Boolean]
        def force_next_move?
          return true
        end

        # Tell if the effect forces the next turn action into a Attack action
        # @return [Boolean]
        def force_next_turn_action?
          return true
        end

        # Function that updates the counter of the effect
        def update_counter
          return if paused?(@pokemon)

          @counter -= 1
          @counter = 0 if interrupted?(@pokemon)
        end

        # List of move that must be paused when user is asleep/frozen/flinched
        MOVES_PAUSED = %i[freeze_shock geomancy ice_burn razor_wind skull_bash sky_attack solar_beam electro_shot]

        # Function that tells us if we should pause the move or not
        # @param user [PFM::PokemonBattler] user of the move
        def paused?(user)
          return true if MOVES_PAUSED.include?(move.db_symbol) && (user.frozen? || user.asleep? || user.effects.has?(:flinch))

          return false
        end

        # Function that tells us if we should interrupt the move or not
        # @param user [PFM::PokemonBattler] user of the move
        def interrupted?(user)
          return true if !MOVES_PAUSED.include?(move.db_symbol) && (user.frozen? || user.asleep? || user.effects.has?(:flinch))

          return false
        end

        # Make the Attack action that is forced by this effect
        # @return [Actions::Attack]
        def make_action
          raise "Failed to make effect for #{self.class}" unless @pokemon && @logic

          target = targets.first
          return action_class.new(@logic.scene, move, @pokemon, target.bank, target.position)
        end

        # Get the class of the action
        # @return [Class<Actions::Attack>]
        def action_class
          Actions::Attack
        end

        private

        # Create a new Forced next move effect
        # @param move [Battle::Move]
        # @param targets [Array<PFM::PokemonBattler>]
        # @param counter [Integer] number of turn the move is forced to be used
        def init_force_next_move(move, targets, counter)
          @move = move
          @targets = targets
          self.counter = counter
        end
      end
    end
  end
end
