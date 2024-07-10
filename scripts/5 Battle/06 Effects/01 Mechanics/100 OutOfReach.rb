module Battle
  module Effects
    module Mechanics
      # Make the pokemon out of reach
      #
      # **Requirement**
      # - Call initialize_out_of_reach
      module OutOfReach
        # Get the move the Pokemon has to use
        # @return [Battle::Move]
        attr_reader :move

        # Init the mechanic
        # @param pokemon [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @param exceptions [Array<Symbol>] move that hit the target while out of reach
        # @param counter [Integer] number of turn the user is out_of_reach
        def initialize_out_of_reach(pokemon, move, exceptions, counter = 2)
          @oor_pokemon = pokemon
          @oor_exceptions = exceptions
          @move = move
          self.counter = counter
        end

        # Tell if the effect make the pokemon out reach
        # @return [Boolean]
        def out_of_reach?
          return true
        end
        alias oor_out_of_reach? out_of_reach?

        # Function that updates the counter of the effect
        def update_counter
          @counter -= 1
          @counter = 0 if interrupted?(@oor_pokemon)
        end

        # List of move that must be paused when user is asleep/frozen/flinched
        MOVES_PAUSED = %i[freeze_shock geomancy ice_burn razor_wind skull_bash sky_attack solar_beam electro_shot]

        # Function that tells us if we should interrupt the move or not
        # @param user [PFM::PokemonBattler] user of the move
        def interrupted?(user)
          return true if move && MOVES_PAUSED.none?(move.db_symbol) && (user.frozen? || user.asleep? || user.effects.has?(:flinch))

          return false
        end

        # Check if the attack can hit the pokemon. Should be called after testing out_of_reach?
        # @param move [Battle::Move]
        # @return [Boolean]
        def can_hit_while_out_of_reach?(move)
          return true if @oor_exceptions.include?(move.db_symbol)
          return true if move.be_method == :s_weather

          return false
        end
        alias oor_can_hit_while_out_of_reach? can_hit_while_out_of_reach?

        # Function called when we try to check if the target evades the move
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler] expected target
        # @param move [Battle::Move]
        # @return [Boolean] if the target is evading the move
        def on_move_prevention_target(user, target, move)
          return false if target != @oor_pokemon

          result = !can_hit_while_out_of_reach?(move)
          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 213, target)) if result

          return result
        end
        alias oor_on_move_prevention_target on_move_prevention_target
      end
    end
  end
end
