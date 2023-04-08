module Battle
  class Move
    # Is the skill a specific type ?
    # @param type_id [Integer] ID of the type
    def type?(type_id)
      return type == type_id
    end

    # Is the skill typeless ?
    # @return [Boolean]
    def typeless?
      return type?(data_type(:__undef__).id)
    end

    # Is the skill type normal ?
    # @return [Boolean]
    def type_normal?
      return type?(data_type(:normal).id)
    end

    # Is the skill type fire ?
    # @return [Boolean]
    def type_fire?
      return type?(data_type(:fire).id)
    end
    alias type_feu? type_fire?

    # Is the skill type water ?
    # @return [Boolean]
    def type_water?
      return type?(data_type(:water).id)
    end
    alias type_eau? type_water?

    # Is the skill type electric ?
    # @return [Boolean]
    def type_electric?
      return type?(data_type(:electric).id)
    end
    alias type_electrique? type_electric?

    # Is the skill type grass ?
    # @return [Boolean]
    def type_grass?
      return type?(data_type(:grass).id)
    end
    alias type_plante? type_grass?

    # Is the skill type ice ?
    # @return [Boolean]
    def type_ice?
      return type?(data_type(:ice).id)
    end
    alias type_glace? type_ice?

    # Is the skill type fighting ?
    # @return [Boolean]
    def type_fighting?
      return type?(data_type(:fighting).id)
    end
    alias type_combat? type_fighting?

    # Is the skill type poison ?
    # @return [Boolean]
    def type_poison?
      return type?(data_type(:poison).id)
    end

    # Is the skill type ground ?
    # @return [Boolean]
    def type_ground?
      return type?(data_type(:ground).id)
    end
    alias type_sol? type_ground?

    # Is the skill type fly ?
    # @return [Boolean]
    def type_flying?
      return type?(data_type(:flying).id)
    end
    alias type_vol? type_flying?
    alias type_fly? type_flying?

    # Is the skill type psy ?
    # @return [Boolean]
    def type_psychic?
      return type?(data_type(:psychic).id)
    end
    alias type_psy? type_psychic?

    # Is the skill type insect/bug ?
    # @return [Boolean]
    def type_insect?
      return type?(data_type(:bug).id)
    end
    alias type_bug? type_insect?

    # Is the skill type rock ?
    # @return [Boolean]
    def type_rock?
      return type?(data_type(:rock).id)
    end
    alias type_roche? type_rock?

    # Is the skill type ghost ?
    # @return [Boolean]
    def type_ghost?
      return type?(data_type(:ghost).id)
    end
    alias type_spectre? type_ghost?

    # Is the skill type dragon ?
    # @return [Boolean]
    def type_dragon?
      return type?(data_type(:dragon).id)
    end

    # Is the skill type steel ?
    # @return [Boolean]
    def type_steel?
      return type?(data_type(:steel).id)
    end
    alias type_acier? type_steel?

    # Is the skill type dark ?
    # @return [Boolean]
    def type_dark?
      return type?(data_type(:dark).id)
    end
    alias type_tenebre? type_dark?

    # Is the skill type fairy ?
    # @return [Boolean]
    def type_fairy?
      return type?(data_type(:fairy).id)
    end
    alias type_fee? type_fairy?

  end
end
