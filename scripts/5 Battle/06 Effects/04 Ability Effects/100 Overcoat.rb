module Battle
  module Effects
    class Ability
      # A Pokémon with Overcoat does not take damage from the weather conditions sandstorm and hailstorm.
      # Also protects from powder and spore moves, as well as Effect Spore.
      # @see https://pokemondb.net/ability/overcoat
      # @see https://bulbapedia.bulbagarden.net/wiki/Overcoat_(Ability)
      # @see https://www.pokepedia.fr/Envelocape
      class Overcoat < Ability
        # Function called when we try to check if the Pokemon is immune to a move due to its effect
        # @param user [PFM::PokemonBattler]
        # @param target [PFM::PokemonBattler]
        # @param move [Battle::Move]
        # @return [Boolean] if the target is immune to the move
        def on_move_ability_immunity(user, target, move)
          return false if target != @target
          return @logic.scene.visual.show_ability(target) && true if move.powder? && user.can_be_lowered_or_canceled?

          return false
        end
      end
      register(:overcoat, Overcoat)
    end
  end
end
