module Battle
  module Effects
    class Ability
      class TeraShell < Ability
        # Function that computes an overwrite of the type multiplier
        # @param target [PFM::PokemonBattler]
        # @param target_type [Integer] one of the type of the target
        # @param type [Integer] one of the type of the move
        # @param move [Battle::Move]
        # @return [Float, nil] overwriten type multiplier
        def on_single_type_multiplier_overwrite(target, target_type, type, move)
          return if target != @target || target.hp != target.max_hp || type == 0
          return 1 if target_type != target.type1

          return 0.5
        end
      end

      register(:tera_shell, TeraShell)
    end
  end
end
