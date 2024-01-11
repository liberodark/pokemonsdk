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

    # Resources of the trainer
    # @return [Resources]
    attr_reader :resources

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

    # Get the victory text of the trainer
    def victory_text
      return text_get(47, @id)
    end

    # Get the defeat text of the trainer
    def defeat_text
      return text_get(48, @id)
    end

    class Resources
      # Sprite of the trainer (Gen 4/5 style)
      # @return [String]
      attr_reader :sprite

      # Full artwork of the trainer (Gen 6+ style)
      # @return [String]
      attr_reader :artwork_full

      # Small artwork of the trainer (Gen 6+ style)
      # @return [String]
      attr_reader :artwork_small

      # Character of the trainer
      # @return [String]
      attr_reader :character

      # BGM played when the enemy trainer sees the player (trainer_eye_sequence)
      # @return [String]
      attr_reader :encounter_bgm

      # BGM played when the enemy trainer wins the battle
      # @return [String]
      attr_reader :victory_bgm

      # BGM played when the enemy trainer loses the battle
      # @return [String]
      attr_reader :defeat_bgm

      # BGM played during the battle
      # @return [String]
      attr_reader :battle_bgm
    end
  end
end
