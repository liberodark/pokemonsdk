module PFM
  # Class defining a Pokemon during a battle, it aim to copy its properties but also to have the methods related to the battle.
  class PokemonBattler24 < PokemonBattler
    # Get the access to the actual pokemon battler object
    # @return [PFM::PokemonBattler]
    attr_reader :pokemon_battler
    # Create a new PokemonBattler24
    # @param battler [PFM::PokemonBattler]
    def initialize(battler)
      @pokemon_battler = battler
      battler.instance_variables.each do |iv|
        instance_variable_set(iv, battler.instance_variable_get(iv))
      end

      @moveset.map!(&:clone)
      @bag = battler.bag
    end

    # Return the .24 position
    def position
      pos = super
      return bank != 0 ? -pos - 1 : pos
    end
  end
end
