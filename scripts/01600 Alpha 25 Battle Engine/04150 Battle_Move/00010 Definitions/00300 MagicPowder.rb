module Battle
  class Move
    # Move that give a third type to an enemy
    class MagicPowder < ChangeType
      
      # Method that tells if the Move's effect can proceed
      # @param target [PFM::PokemonBattler]
      # @return [Boolean]
      def condition(target)
        target.type_psychic? && target.type2 == 0 && target.type3 == 0 && ABILITY_EXCEPTION.include?(target.ability_db_symbol)
      end
    end
    Move.register(:s_magic_powder, MagicPowder)
  end
end
