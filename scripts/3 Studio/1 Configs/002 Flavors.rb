module Configs
  # Configuration of flavors
  class Flavors
    # Get the ID of spicy flavor
    # @return [Integer]
    attr_accessor :spicy

    # Get the ID of dry flavor
    # @return [Integer]
    attr_accessor :dry

    # Get the ID of sweet flavor
    # @return [Integer]
    attr_accessor :sweet

    # Get the ID of bitter flavor
    # @return [Integer]
    attr_accessor :bitter

    # Get the ID of sour flavor
    # @return [Integer]
    attr_accessor :sour

    # List of nature with no preferences
    # @return [Array<Integer>]
    attr_reader :nature_with_no_preferences

    # List of nature liking flavor by flavor
    # @return [Hash<Symbol => Array<Integer>>]
    attr_reader :nature_liking_flavor

    # List of nature disliking flavor by flavor
    # @return [Hash<Symbol => Array<Integer>>]
    attr_reader :nature_disliking_flavor

    # Set the nature with no preferences
    def nature_with_no_preferences=(arr)
      @nature_with_no_preferences = arr.map { |value| Configs.natures.db_symbol_to_id[value.to_sym] }
    end

    # Set the nature liking flavor
    def nature_liking_flavor=(hash)
      @nature_liking_flavor = hash
      hash.each_value { |v| v.map! { |value| Configs.natures.db_symbol_to_id[value.to_sym] } }
    end

    # Set the nature liking flavor
    def nature_disliking_flavor=(hash)
      @nature_disliking_flavor = hash
      hash.each_value { |v| v.map! { |value| Configs.natures.db_symbol_to_id[value.to_sym] } }
    end

    def initialize
      @spicy = 0
      @dry = 1
      @sweet = 2
      @bitter = 3
      @sour = 4
      self.nature_with_no_preferences = %i[bashful docile hardy quirky serious]
      self.nature_liking_flavor = {
        spicy: %i[adamant brave naughty lonely],
        dry: %i[modest quiet rash mild],
        sweet: %i[timid jolly naive hasty],
        bitter: %i[calm careful sassy gentle],
        sour: %i[bold impish relaxed lax]
      }
      self.nature_disliking_flavor = {
        spicy: %i[modest timid calm bold],
        dry: %i[adamant jolly careful impish],
        sweet: %i[brave quiet sassy relaxed],
        bitter: %i[naughty rash naive lax],
        sour: %i[lonely mild hasty gentle]
      }
    end

    # Convert the config to json
    def to_json(*)
      {
        klass: self.class.to_s,
        spicy: @spicy,
        dry: @dry,
        sweet: @sweet,
        bitter: @bitter,
        sour: @sour,
        nature_with_no_preferences: @nature_with_no_preferences,
        nature_liking_flavor: @nature_liking_flavor,
        nature_disliking_flavor: @nature_disliking_flavor
      }.to_json
    end
  end
  # @!method self.flavors
  #   @return [Flavors]
  register(:flavors, 'flavors', :json, false, Flavors)
end
