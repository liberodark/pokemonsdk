module Studio
  # Data class describing a creature form
  class CreatureForm < Creature
    undef forms

    # Current form ID
    # @return [Integer]
    attr_reader :form

    # Height of the form
    # @return [Float]
    attr_reader :height

    # Weight of the form
    # @return [Float]
    attr_reader :weight

    # Symbol of the first type of the form
    # @return [Symbol]
    attr_reader :type1

    # Symbol of the second type of the form
    # @return [Symbol]
    attr_reader :type2

    # Base hp of the form
    # @return [Integer]
    attr_reader :base_hp

    # Base atk of the form
    # @return [Integer]
    attr_reader :base_atk

    # Base dfe of the form
    # @return [Integer]
    attr_reader :base_dfe

    # Base spd of the form
    # @return [Integer]
    attr_reader :base_spd

    # Base ats of the form
    # @return [Integer]
    attr_reader :base_ats

    # Base dfs of the form
    # @return [Integer]
    attr_reader :base_dfs

    # HP EV given by this form when fainted
    # @return [Integer]
    attr_reader :ev_hp

    # Atk EV given by this form when fainted
    # @return [Integer]
    attr_reader :ev_atk

    # Dfe EV given by this form when fainted
    # @return [Integer]
    attr_reader :ev_dfe

    # Spd EV given by this form when fainted
    # @return [Integer]
    attr_reader :ev_spd

    # Ats EV given by this form when fainted
    # @return [Integer]
    attr_reader :ev_ats

    # Dfs EV given by this form when fainted
    # @return [Integer]
    attr_reader :ev_dfs

    # All the evolutions of that form
    # @return [Array<Evolution>]
    attr_reader :evolutions

    # Type of exp curve for the form
    # @return [Integer]
    attr_reader :experience_type

    # Base experience use in exp calculation when fainted
    # @return [Integer]
    attr_reader :base_experience

    # Loyalty the creature have when caught
    # @return [Integer]
    attr_reader :base_loyalty

    # Catch rate of the creature
    # @return [Integer]
    attr_reader :catch_rate

    # Female rate of the creature
    # @return [Integer]
    attr_reader :female_rate

    # List of breed groups of the creature
    # @return [Array<Integer>]
    attr_reader :breed_groups

    # Number of steps before the egg hatches
    # @return [Integer]
    attr_reader :hatch_steps

    # db_symbol of the baby creature
    # @return [Symbol]
    attr_reader :baby_db_symbol

    # Form of the baby
    # @return [Integer]
    attr_reader :baby_form

    # Item held by the creature when encountered
    # @return [Array<ItemHeld>]
    attr_reader :item_held

    # Abilities the creature can have
    # @return [Array<Symbol>]
    attr_reader :abilities

    # Front offset y of the creature so it can be centered in the UI
    # @return [Integer]
    attr_reader :front_offset_y

    # Moveset of the creature
    # @return [Array<LearnableMove>]
    attr_reader :move_set

    # Resources of the creature
    # @return [Resources]
    attr_reader :resources

    # Data class describing an evolution
    class Evolution
      # db_symbol of the creature to evolve to
      # @return [Symbol]
      attr_reader :db_symbol

      # Form of the creature to evolve to
      # @return [Integer]
      attr_reader :form

      # Conditions of the evolution
      # @return [Array<Hash>]
      attr_reader :conditions

      # Get data by condition
      # @param type [Symbol] type of condition to check
      # @return [Symbol, Integer]
      def condition_data(type)
        condition = @conditions.find { |cdn| cdn[:type] == type }
        return condition && condition[:value]
      end
    end

    # Item held by the creature when generated
    class ItemHeld
      # db_symbol of the item that should be held
      # @return [Symbol]
      attr_reader :db_symbol

      # Chance that the creature is holding this item
      # @return [Integer]
      attr_reader :chance
    end

    # Resource of the creature for UI purpose
    class Resources
      # Standard icon
      # @return [String]
      attr_reader :icon

      # Female icon
      # @return [String, nil]
      attr_reader :icon_f

      # Standard shiny icon
      # @return [String]
      attr_reader :icon_shiny

      # Female shiny icon
      # @return [String, nil]
      attr_reader :icon_shiny_f

      # Standard front
      # @return [String]
      attr_reader :front

      # Female front
      # @return [String, nil]
      attr_reader :front_f

      # Standard shiny front
      # @return [String]
      attr_reader :front_shiny

      # Female shiny front
      # @return [String, nil]
      attr_reader :front_shiny_f

      # Standard back
      # @return [String]
      attr_reader :back

      # Female back
      # @return [String, nil]
      attr_reader :back_f

      # Standard shiny back
      # @return [String]
      attr_reader :back_shiny

      # Female shiny back
      # @return [String, nil]
      attr_reader :back_shiny_f

      # Footprint
      # @return [String]
      attr_reader :footprint

      # Standard character
      # @return [String]
      attr_reader :character

      # Female character
      # @return [String, nil]
      attr_reader :character_f

      # Standard shiny character
      # @return [String]
      attr_reader :character_shiny

      # Female shiny character
      # @return [String, nil]
      attr_reader :character_shiny_f

      # Cry
      # @return [String]
      attr_reader :cry

      # Test if the females resources can be used
      # @return [Boolean]
      attr_reader :has_female
    end
  end

  # Data class describing a learnable move
  class LearnableMove
    # db_symbol of the move that can be learnt
    # @return [Symbol]
    attr_reader :move

    # Test if the move is learnable by level
    # @return [Boolean]
    def level_learnable?
      false
    end

    # Test if the move is learnable by tutor
    # @return [Boolean]
    def tutor_learnable?
      false
    end

    # Test if the move is learnable by tech item
    # @return [Boolean]
    def tech_learnable?
      false
    end

    # Test if the move is learnable by breeding
    # @return [Boolean]
    def breed_learnable?
      false
    end

    # Test if the move is learnable by evolution
    # @return [Boolean]
    def evolution_learnable?
      false
    end
  end

  # Data class describing a move learnable by level
  class LevelLearnableMove < LearnableMove
    # Level when the move can be learnt
    # @return [Integer]
    attr_reader :level

    # Test if the move is learnable by level
    # @return [Boolean]
    def level_learnable?
      true
    end
  end

  # Data class describing a move that can be teached by a Move Tutor
  class TutorLearnableMove < LearnableMove
    # Test if the move is learnable by tutor
    # @return [Boolean]
    def tutor_learnable?
      true
    end
  end

  # Data class decribing a move that can be teached using a TechItem
  class TechLearnableMove < LearnableMove
    # Test if the move is learnable by tech item
    # @return [Boolean]
    def tech_learnable?
      true
    end
  end

  # Data class describing a move that can be learnt through breeding
  class BreedLearnableMove < LearnableMove
    # Test if the move is learnable by breeding
    # @return [Boolean]
    def breed_learnable?
      true
    end
  end

  # Data class describing a move that can be learnt through evolution
  class EvolutionLearnableMove < LearnableMove
    # Test if the move is learnable by evolution
    # @return [Boolean]
    def evolution_learnable?
      true
    end
  end
end
