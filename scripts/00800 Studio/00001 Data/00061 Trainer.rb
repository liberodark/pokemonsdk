module Studio
  # Data class describing a trainer
  class Trainer
    # ID of the trainer
    # @return [Integer]
    attr_reader :id

    # db_symbol of the trainer
    # @return [Symbol]
    attr_reader :db_symbol

    # vs type of the trainer (if he uses 1 2 or more creature at once)
    # @return [Integer]
    attr_reader :vs_type

    # If the trainer is actually a couple (two trainer on same picture)
    # @return [Boolean]
    attr_reader :is_couple

    # Base factor of the money gave by this trainer in case of defeate (money = base * last_level)
    # @return [Integer]
    attr_reader :base_money

    # ID of the battler events to load in order to give more life to this trainer
    # @return [Integer]
    attr_reader :battle_id

    # AI level of that trainer
    # @return [Integer]
    attr_reader :ai

    # Party of that trainer
    # @return [Array<Group::Encounter>]
    attr_reader :party

    # List of all items the trainer holds in its bag
    # @return [Array<Hash>]
    attr_reader :bag_entries

    # Get the graphic battler of the trainer
    # @return [String]
    def battler
      return @battlers.is_a?(String) ? @battlers : (@battlers.first || '__undefined__')
    end

    # Get the class name of the trainer
    # @return [String]
    def class_name
      return text_get(29, @id)
    end

    # Get the text name of the trainer
    # @return [String]
    def name
      return text_get(62, @id)
    end
  end
end
