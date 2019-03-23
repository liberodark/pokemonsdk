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

    private

    # Load the battlers from the battle infos
    def load_battlers
      @battle_info.parties.each_with_index do |parties, bank|
        next unless parties
        parties.each_with_index do |party, index|
          load_battlers_from_party(party, bank, index)
        end
      end
    end

    # Load the battlers from a party
    # @param party [Array<PFM::Pokemon>]
    # @param bank [Integer]
    # @param index [Integer] index of the party in the parties array (party_id)
    def load_battlers_from_party(party, bank, index)
      party = sort_party(party)
      battlers = (@battlers[bank] ||= [])
      max_level = @battle_info.max_level
      party.each do |pokemon|
        battler = max_level ? PFM::PokemonBattler.new(pokemon, max_level) : PFM::PokemonBattler.new(pokemon)
        battler.bank = bank
        battler.party_id = index
        battlers << battler
      end
    end

    # Sort a party (push the dead mon at the end)
    # @param party [Array<PFM::Pokemon>]
    # @return [Array<PFM::Pokemon>]
    def sort_party(party)
      party.compact.sort do |a, b|
        a = a.dead? ? 1 : 0
        b = b.dead? ? 1 : 0
        a <=> b
      end
    end
  end
end
