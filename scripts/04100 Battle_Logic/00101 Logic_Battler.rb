module Battle
  class Logic
    # Return the battler of a bank
    # @param bank [Integer] bank where the Pokemon is
    # @param position [Integer] position of the Pokemon in the bank
    # @return [PFM::PokemonBattler, nil]
    def battler(bank, position)
      return nil if position < 0
      return @battlers.dig(bank, position)
    end

  end
end
