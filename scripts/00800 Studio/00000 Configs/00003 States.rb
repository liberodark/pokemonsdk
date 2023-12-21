module Configs
  # Configuration of states
  class States
    # Get the ID of states
    # @return [Hash<Symbol => Integer>]
    attr_accessor :ids

    def initialize
      @ids = {
        poison: 1,
        paralysis: 2,
        burn: 3,
        sleep: 4,
        freeze: 5,
        confusion: 6,
        toxic: 8,
        death: 9,
        ko: 9,
        flinch: 7
      }
    end

    # Get the symbol of a state from its id
    # @return [Symbol, nil]
    def symbol(id)
      @ids.key(id)
    end

    # Convert the config to json
    def to_json(*)
      {
        klass: self.class.to_s,
        ids: @ids
      }.to_json
    end
  end
  # @!method self.states
  #   @return [States]
  register(:states, 'states', :json, false, States)
end
