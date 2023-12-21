module Configs
  # Configuration of natures
  class Natures
    # Get the nature data
    # @return [Array<Array<Integer>]
    attr_accessor :data

    # Get the nature ids
    # @return [Hash<Symbol => Integer>]
    attr_accessor :db_symbol_to_id

    def initialize
      @data = [
        [0, 100, 100, 100, 100, 100],
        [1, 110, 90, 100, 100, 100],
        [2, 110, 100, 90, 100, 100],
        [3, 110, 100, 100, 90, 100],
        [4, 110, 100, 100, 100, 90],
        [5, 90, 110, 100, 100, 100],
        [6, 100, 100, 100, 100, 100],
        [7, 100, 110, 90, 100, 100],
        [8, 100, 110, 100, 90, 100],
        [9, 100, 110, 100, 100, 90],
        [10, 90, 100, 110, 100, 100],
        [11, 100, 90, 110, 100, 100],
        [12, 100, 100, 100, 100, 100],
        [13, 100, 100, 110, 90, 100],
        [14, 100, 100, 110, 100, 90],
        [15, 90, 100, 100, 110, 100],
        [16, 100, 90, 100, 110, 100],
        [17, 100, 100, 90, 110, 100],
        [18, 100, 100, 100, 100, 100],
        [19, 100, 100, 100, 110, 90],
        [20, 90, 100, 100, 100, 110],
        [21, 100, 90, 100, 100, 110],
        [22, 100, 100, 90, 100, 110],
        [23, 100, 100, 100, 90, 110],
        [24, 100, 100, 100, 100, 100]
      ]
      @db_symbol_to_id = {
        hardy: 0,
        lonely: 1,
        brave: 2,
        adamant: 3,
        naughty: 4,
        bold: 5,
        docile: 6,
        relaxed: 7,
        impish: 8,
        lax: 9,
        timid: 10,
        hasty: 11,
        serious: 12,
        jolly: 13,
        naive: 14,
        modest: 15,
        mild: 16,
        quiet: 17,
        bashful: 18,
        rash: 19,
        calm: 20,
        gentle: 21,
        sassy: 22,
        careful: 23,
        quirky: 24
      }
    end

    # Get an ability data by id or db_symbol
    # @param db_symbol [Symbol]
    # @return [Array<Integer>]
    def [](db_symbol)
      return @data[@db_symbol_to_id[db_symbol] || 0] || @data.first if db_symbol.is_a?(Symbol)

      return @data[db_symbol] || @data.first
    end

    # Convert the config to json
    def to_json(*)
      {
        klass: self.class.to_s,
        data: @data,
        db_symbol_to_id: @db_symbol_to_id
      }.to_json
    end
  end
  # @!method self.natures
  #   @return [Natures]
  register(:natures, 'natures', :json, true, Natures)
end
