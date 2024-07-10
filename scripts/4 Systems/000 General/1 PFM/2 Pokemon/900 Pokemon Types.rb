module PFM
  class Pokemon
    # Return the current first type of the Pokemon
    # @return [Integer]
    def type1
      return data_type(data.type1).id
    end

    # Return the current second type of the Pokemon
    # @return [Integer]
    def type2
      return data_type(data.type2).id
    end

    # Return the current third type of the Pokemon
    # @return [Integer]
    def type3
      return 0
    end

    # Is the Pokemon type normal ?
    # @return [Boolean]
    def type_normal?
      return type?(data_type(:normal).id)
    end

    # Is the Pokemon type fire ?
    # @return [Boolean]
    def type_fire?
      return type?(data_type(:fire).id)
    end
    alias type_feu? type_fire?

    # Is the Pokemon type water ?
    # @return [Boolean]
    def type_water?
      return type?(data_type(:water).id)
    end
    alias type_eau? type_water?
    # Is the Pokemon type electric ?
    # @return [Boolean]
    def type_electric?
      return type?(data_type(:electric).id)
    end
    alias type_electrique? type_electric?

    # Is the Pokemon type grass ?
    # @return [Boolean]
    def type_grass?
      return type?(data_type(:grass).id)
    end
    alias type_plante? type_grass?

    # Is the Pokemon type ice ?
    # @return [Boolean]
    def type_ice?
      return type?(data_type(:ice).id)
    end
    alias type_glace? type_ice?

    # Is the Pokemon type fighting ?
    # @return [Boolean]
    def type_fighting?
      return type?(data_type(:fighting).id)
    end
    alias type_combat? type_fighting?

    # Is the Pokemon type poison ?
    # @return [Boolean]
    def type_poison?
      return type?(data_type(:poison).id)
    end

    # Is the Pokemon type ground ?
    # @return [Boolean]
    def type_ground?
      return type?(data_type(:ground).id)
    end
    alias type_sol? type_ground?

    # Is the Pokemon type fly ?
    # @return [Boolean]
    def type_flying?
      return type?(data_type(:flying).id)
    end
    alias type_vol? type_flying?
    alias type_fly? type_flying?

    # Is the Pokemon type psy ?
    # @return [Boolean]
    def type_psychic?
      return type?(data_type(:psychic).id)
    end
    alias type_psy? type_psychic?

    # Is the Pokemon type insect/bug ?
    # @return [Boolean]
    def type_bug?
      return type?(data_type(:bug).id)
    end
    alias type_insect? type_bug?

    # Is the Pokemon type rock ?
    # @return [Boolean]
    def type_rock?
      return type?(data_type(:rock).id)
    end
    alias type_roche? type_rock?

    # Is the Pokemon type ghost ?
    # @return [Boolean]
    def type_ghost?
      return type?(data_type(:ghost).id)
    end
    alias type_spectre? type_ghost?

    # Is the Pokemon type dragon ?
    # @return [Boolean]
    def type_dragon?
      return type?(data_type(:dragon).id)
    end

    # Is the Pokemon type steel ?
    # @return [Boolean]
    def type_steel?
      return type?(data_type(:steel).id)
    end
    alias type_acier? type_steel?

    # Is the Pokemon type dark ?
    # @return [Boolean]
    def type_dark?
      return type?(data_type(:dark).id)
    end
    alias type_tenebre? type_dark?

    # Is the Pokemon type fairy ?
    # @return [Boolean]
    def type_fairy?
      return type?(data_type(:fairy).id)
    end
    alias type_fee? type_fairy?

    # Check the Pokemon type by the type ID
    # @param type [Integer] ID of the type in the database
    # @return [Boolean]
    def type?(type)
      return (type1 == type || type2 == type || (type3 == type && type != 0))
    end

    # Is the Pokemon typeless ?
    # @return [Boolean]
    def typeless?
      return type1 == 0 && type2 == 0 && type3 == 0
    end

    # Is the user single typed ?
    # @return [Boolean]
    def single_type?
      return type1 != 0 && type2 == 0 && type3 == 0
    end

    # Has the user a third type ?
    # @return [Boolean]
    def third_type?
      type3 != 0
    end
  end
end
