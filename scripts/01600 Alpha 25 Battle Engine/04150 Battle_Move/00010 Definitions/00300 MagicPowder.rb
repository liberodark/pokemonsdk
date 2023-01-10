module Battle
  class Move
    # Move that give a third type to an enemy
    class MagicPowder < ChangeType
      # Test if the target is immune
      # @param user [PFM::PokemonBattler]
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def target_immune?(user, target)
        if target.hold_item?(:safety_goggles)
          @logic.scene.visual.show_item(target)

          return true
        end

        return super ? true : false
      end

      # Method that tells if the target already has the type
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def type_check(target)
        return target.type_psychic?
      end
    end
    Move.register(:s_magic_powder, MagicPowder)
  end
end
