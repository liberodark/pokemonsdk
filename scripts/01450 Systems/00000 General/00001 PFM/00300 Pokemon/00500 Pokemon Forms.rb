# encoding: utf-8

module PFM
  class Pokemon
    # List of form calibration hook for Creatures that needs form calibration (when switching items, being place in computer or when team changes)
    FORM_CALIBRATE = {}
    # List of form generation hook for Creatures that needs an initial form when the PFM::Pokemon object is generated.
    FORM_GENERATION = {}
    # List of items (in the form index order) that change the form of Arceus
    ArceusItem = %i[__undef__ flame_plate splash_plate zap_plate meadow_plate
                    icicle_plate fist_plate toxic_plate earth_plate sky_plate
                    mind_plate insect_plate stone_plate spooky_plate draco_plate
                    iron_plate dread_plate pixie_plate]
    # List of items (in the form index order) that change the form of Genesect
    GenesectModules = %i[__undef__ burn_drive chill_drive douse_drive shock_drive]
    # List of item (in the form index oreder) that change the form of Silvally
    SilvallyROM = %i[__undef__ fighting_memory flying_memory poison_memory
                     ground_memory rock_memory bug_memory ghost_memory steel_memory
                     __undef__ fire_memory water_memory grass_memory electric_memory
                     psychic_memory ice_memory dragon_memory dark_memory fairy_memory]
    # List of items (in the form index order) that change the form of Ogerpon
    OGERPONMASK = %i[__undef__ wellspring_mask hearthflame_mask cornerstone_mask]
    # Change the form of the Pokemon
    # @note If the form doesn't exist, the form is not changed
    # @param value [Integer] the new form index
    def form=(value)
      value = value.to_i
      if data_creature(db_symbol).forms.any? { |creature_form| creature_form.form == value }
        @form = value
        form_calibrate
        update_ability
      end
    end

    # Check if the Pokemon can mega evolve
    # @return [Integer, false] form index if the Pokemon can mega evolve, false otherwise
    def can_mega_evolve?
      return false if mega_evolved?
      return 30 if db_symbol == :rayquaza && skills_set.any? { |skill| skill.db_symbol == :dragon_ascent }

      item = item_db_symbol
      mega_evolution = data.evolutions.find { |evolution| evolution.condition_data(:gemme) == item }

      return mega_evolution ? mega_evolution.form : false
    end

    # Mega evolve the Pokemon (if possible)
    def mega_evolve
      mega_evolution = can_mega_evolve?
      return unless mega_evolution

      @mega_evolved = @form
      @form = mega_evolution
      @ability = data_ability(data.abilities.sample).id
      self.ability = nil if self.is_a?(PFM::PokemonBattler)
    end

    # Reset the Pokemon to its normal form after mega evolution
    def unmega_evolve
      if @mega_evolved
        @form = @mega_evolved
        restore_ability # Pokemon will always be a PFM::PokemonBattler
        @mega_evolved = false
      end
    end

    # Is the Pokemon mega evolved ?
    def mega_evolved?
      return @mega_evolved != false
    end

    # Absofusion of the Pokemon (if possible)
    # @param pokemon PFM::Pokemon The Pokemon used in the fusion
    def absofusion(pokemon)
      return if @fusion
      return unless form_calibrate(pokemon.db_symbol)

      @fusion = pokemon
      $actors.delete(pokemon)
    end

    # Separate (if possible) the Pokemon and restore the Pokemon used in the fusion
    def separate
      return unless @fusion || $actors.size != 6

      form_calibrate(:none)
      $actors << @fusion
      @fusion = nil
    end

    # If the Pokemon is a absofusion
    def absofusionned?
      return !@fusion.nil?
    end

    # Automatically generate the form index of the Pokemon
    # @note It calls the block stored in the hash FORM_GENERATION where the key is the Pokemon db_symbol
    # @param form [Integer] if form != 0 does not generate the form (protection)
    # @return [Integer] the form index
    def form_generation(form, old_value = nil)
      form = old_value if old_value
      return form if form != -1

      @character = nil
      block = FORM_GENERATION[db_symbol]
      return instance_exec(&block).to_i if block

      return 0
    end

    # Automatically calibrate the form of the Pokemon
    # @note It calls the block stored in the hash FORM_CALIBRATE where the key is the Pokemon db_symbol &
    #   the block parameter is the reason. The block should change @form
    # @param reason [Symbol] what called form_calibrate (:menu, :evolve, :load, ...)
    # @return [Boolean] if the Pokemon's form has changed
    def form_calibrate(reason = :menu)
      @character = nil
      last_form = @form
      block = FORM_CALIBRATE[db_symbol]
      instance_exec(reason, &block) if block
      # Set the form to 0 if the form does not exists in the Database
      @form = 0 if data_creature(db_symbol).forms.none? { |creature_form| creature_form.form == @form }
      # Update the ability
      update_ability
      return last_form != @form
    end

    # Calculate the form of deerling & sawsbuck
    # @return [Integer] the right form
    def current_deerling_form
      time = Time.new
      case time.month
      when 1, 2
        return @form = 3
      when 3
        return @form = (time.day < 21 ? 3 : 0)
      when 6
        return @form = (time.day < 21 ? 0 : 1)
      when 7, 8
        return @form = 1
      when 9
        return @form = (time.day < 21 ? 1 : 2)
      when 10, 11
        return @form = 2
      when 12
        return @form = (time.day < 21 ? 2 : 3)
      end
      return @form = 0
    end

    # Determine the form of Shaymin
    # @param reason [Symbol]
    def shaymin_form(reason)
      return 0 if frozen?
      return 1 if @form == 1 && ($env.morning? || $env.day?)
      return 1 if reason == :gracidea && ($env.morning? || $env.day?)

      return 0
    end

    # Determine the form of the Kyurem
    # @param [Symbol] reason The db_symbol of the Pokemon used for the fusion
    def kyurem_form(reason)
      return @form unless %i[reshiram zekrom none].include?(reason)
      return 1 if reason == :zekrom
      return 2 if reason == :reshiram

      return 0
    end

    # Determine the form of the Necrozma
    # @param [Symbol] reason The db_symbol of the Pokemon used for the fusion
    def necrozma_form(reason)
      return @form unless %i[solgaleo lunala none].include?(reason)
      return 1 if reason == :solgaleo
      return 2 if reason == :lunala

      return 0
    end

    # Determine the form of the Zygarde
    # @param reason [Symbol]
    # @return [Integer] form of zygarde
    def zygarde_form(reason)
      current_hp = @hp
      @base_form = @form unless @form == 3

      new_form = 3 if !dead? && hp_rate <= 0.5 && reason == :battle
      @form = new_form || @base_form || 1
      self.hp = current_hp
      return @form
    end

    # Determine the form of Cramorant
    # @param reason [Symbol]
    def cramorant_form(reason)
      return 0 if reason == :base
      return 1 if reason == :arrokuda
      return 2 if reason == :pikachu

      return 0
    end

    # Determine the form of the Calyrex
    # @param [Symbol] reason The db_symbol of the Pokemon used for the fusion
    def calyrex_form(reason)
      return @form unless %i[glastrier spectrier none].include?(reason)
      return 1 if reason == :glastrier
      return 2 if reason == :spectrier

      return 0
    end

    # Determine the form of Castform
    # @param reason [Symbol]
    def castform_form(reason)
      return 2 if reason == :fire
      return 3 if reason == :rain
      return 6 if reason == :ice

      return 0
    end

    FORM_GENERATION[:unown] = proc { @form = @code % 28 }

    FORM_GENERATION[:burmy] = FORM_GENERATION[:wormadam] = proc do
      env = $env
      if env.building?
        next @form = 2
      elsif env.grass? || env.tall_grass? || env.very_tall_grass?
        next @form = 0
      end

      next @form = 1
    end

    FORM_GENERATION[:cherrim] = proc { @form = $env.sunny? || $env.hardsun? ? 1 : 0 }
    FORM_GENERATION[:deerling] = FORM_GENERATION[:sawsbuck] = proc { @form = current_deerling_form }
    FORM_GENERATION[:meowstic] = proc { @form = @gender == 2 ? 1 : 0 }

    FORM_CALIBRATE[:giratina] = proc { @form = item_db_symbol == :griseous_orb ? 1 : 0 }
    FORM_CALIBRATE[:arceus] = proc { @form = ArceusItem.index(item_db_symbol).to_i }
    FORM_CALIBRATE[:shaymin] = proc { |reason| @form = shaymin_form(reason) }
    FORM_CALIBRATE[:genesect] = proc { @form = GenesectModules.index(item_db_symbol).to_i }
    FORM_CALIBRATE[:silvally] = proc { @form = SilvallyROM.index(item_db_symbol).to_i }
    FORM_CALIBRATE[:deerling] = FORM_CALIBRATE[:sawsbuck] = proc { @form = current_deerling_form }
    FORM_CALIBRATE[:darmanitan] = proc { |reason| @form = hp_rate <= 0.5 && reason == :battle ? @form | 1 : @form & ~1 }
    FORM_CALIBRATE[:tornadus] = proc { |reason| @form = reason == :therian ? 1 : 0 }
    FORM_CALIBRATE[:thundurus] = proc { |reason| @form = reason == :therian ? 1 : 0 }
    FORM_CALIBRATE[:landorus] = proc { |reason| @form = reason == :therian ? 1 : 0 }
    FORM_CALIBRATE[:kyurem] = proc { |reason| @form = kyurem_form(reason) }
    FORM_CALIBRATE[:keldeo] = proc { @form = find_skill(:secret_sword) ? 1 : 0 }
    FORM_CALIBRATE[:meloetta] = proc { |reason| @form = reason == :dance ? 1 : 0 }
    FORM_CALIBRATE[:aegislash] = proc { |reason| @form = reason == :blade ? 0 : 1 }
    FORM_CALIBRATE[:necrozma] = proc { |reason| @form = necrozma_form(reason) }
    FORM_CALIBRATE[:mimikyu] = proc { |reason| @form = reason == :battle ? 1 : 0 }
    FORM_CALIBRATE[:eiscue] = proc { |reason| @form = reason == :battle ? 1 : 0 }
    FORM_CALIBRATE[:zacian] = proc { @form = item_db_symbol == :rusted_sword ? 1 : 0 }
    FORM_CALIBRATE[:zamazenta] = proc { @form = item_db_symbol == :rusted_shield ? 1 : 0 }
    FORM_CALIBRATE[:calyrex] = proc { |reason| @form = calyrex_form(reason) }
    FORM_CALIBRATE[:groudon] = proc { @form = item_db_symbol == :red_orb ? 1 : 0 }
    FORM_CALIBRATE[:kyogre] = proc { @form = item_db_symbol == :blue_orb ? 1 : 0 }
    FORM_CALIBRATE[:wishiwashi] = proc { |reason| @form = hp_rate >= 0.25 && level >= 20 && reason == :battle ? 1 : 0 }
    FORM_CALIBRATE[:minior] = proc { |reason| @form = hp_rate <= 0.5 && reason == :battle ? @form | 1 : 0 }
    FORM_CALIBRATE[:zygarde] = proc { |reason| @form = zygarde_form(reason) }
    FORM_CALIBRATE[:morpeko] = proc { |reason| @form = reason == :battle ? 1 : 0 }
    FORM_CALIBRATE[:greninja] = proc { |reason| @form = reason == :battle ? 1 : 0 }
    FORM_CALIBRATE[:cramorant] = proc { |reason| @form = cramorant_form(reason) }
    FORM_CALIBRATE[:palafin] = proc { |reason| @form = reason == :hero ? 1 : 0 }
    FORM_CALIBRATE[:castform] = proc { |reason| @form = castform_form(reason) }
    FORM_CALIBRATE[:ogerpon] = proc { @form = OGERPONMASK.index(item_db_symbol).to_i }
  end
end
