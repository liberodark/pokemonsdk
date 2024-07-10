module PFM
  class Pokemon
    include Hooks
    # List of key in evolution Hash that corresponds to the expected ID when evolution is valid
    # @return [Array<Symbol>]
    SPECIAL_EVOLUTION_ID = %i[trade id]

    # List of evolution criteria
    # @return [Hash{ Symbol => Proc }]
    @evolution_criteria = {}
    # List of evolution criteria required for specific reason
    # @return [Hash{ Symbol => Array<Symbol> }]
    @evolution_reason_required_criteria = {}
    class << self
      # List of evolution criteria
      # @return [Hash{ Symbol => Proc }]
      attr_reader :evolution_criteria
      # List of evolution criteria required for specific reason
      # @return [Hash{ Symbol => Array<Symbol> }]
      attr_reader :evolution_reason_required_criteria

      # Add a new evolution criteria
      # @param key [Symbol] hash key expected in special evolution
      # @param reasons [Array<Symbol>] evolution reasons that require this criteria in order to allow evolution
      # @param block [Proc] executed proc for special evolution test, will receive : value, extend_data, reason
      def add_evolution_criteria(key, reasons = nil, &block)
        @evolution_criteria[key] = block
        reasons&.each do |reason|
          (@evolution_reason_required_criteria[reason] ||= []) << key
        end
      end
    end

    # Return the base experience of the Pokemon
    # @return [Integer]
    def base_exp
      return data.base_experience
    end

    # Return the exp curve type ID
    # @return [Integer]
    def exp_type
      return data.experience_type
    end

    # Return the exp curve
    # @return [ExpList]
    def exp_list
      return ExpList.new(exp_type)
    end

    # Return the required total exp (so including old levels) to increase the Pokemon's level
    # @return [Integer]
    def exp_lvl
      data = exp_list
      v = data[@level + 1]
      return data[@level] if !v || PFM.game_state&.level_max_limit.to_i <= @level

      return v
    end

    # Return the text of the amount of exp the pokemon needs to go to the next level
    # @return [String]
    def exp_remaining_text
      expa = exp_lvl - exp
      expa = 0 if expa < 0
      return expa.to_s
    end

    # Return the text of the current pokemon experience
    # @return [String]
    def exp_text
      @exp.to_s
    end

    # Change the Pokemon total exp
    # @param v [Integer] the new exp value
    def exp=(v)
      @exp = v.to_i
      exp_lvl = self.exp_lvl
      if exp_lvl >= @exp
        exp_last = exp_list[@level]
        delta = exp_lvl - exp_last
        current = exp - exp_last
        @exp_rate = (delta == 0 ? 1 : current / delta.to_f)
      else
        @exp_rate = (@level < PFM.game_state.level_max_limit ? 1 : 0)
      end
    end

    # Increase the level of the Pokemon
    # @return [Boolean] if the level has successfully been increased
    def level_up
      return false if @level >= PFM.game_state.level_max_limit

      exp_last = exp_list[@level]
      delta = exp_lvl - exp_last
      self.exp += (delta - (exp - exp_last))
      return true
    end

    # Update the PFM::Pokemon loyalty
    def update_loyalty
      value = 3
      value = 4 if loyalty < 200
      value = 5 if loyalty < 100
      value *= 2 if data_item(captured_with).db_symbol == :luxury_ball
      value *= 1.5 if item_db_symbol == :soothe_bell
      self.loyalty += value.floor
    end

    # Generate the level up stat list for the level up window
    # @return [Array<Array<Integer>>] list0, list1 : old, new basis value
    def level_up_stat_refresh
      list0 = [max_hp, atk_basis, dfe_basis, ats_basis, dfs_basis, spd_basis]
      @level += 1 if @level < PFM.game_state.level_max_limit
      self.exp = exp_list[@level] if @exp < exp_list[@level].to_i
      self.exp = exp # Fix the exp amount
      hp_diff = list0[0] - @hp
      list1 = [max_hp, atk_basis, dfe_basis, ats_basis, dfs_basis, spd_basis]
      self.hp = (max_hp - hp_diff) if @hp > 0
      return [list0, list1]
    end

    # Show the level up window
    # @param list0 [Array<Integer>] old basis stat list
    # @param list1 [Array<Integer>] new basis stat list
    # @param z_level [Integer] z superiority of the Window
    def level_up_window_call(list0, list1, z_level)
      vp = $scene&.viewport
      window = UI::LevelUpWindow.new(vp, self, list0, list1)
      window.z = z_level
      Graphics.sort_z
      until Input.trigger?(:A)
        window.update
        Graphics.update
      end
      $game_system.se_play($data_system.decision_se)
      window.dispose
    end

    # Change the level of the Pokemon
    # @param lvl [Integer] the new level of the Pokemon
    def level=(lvl)
      return if lvl == @level

      lvl = lvl.clamp(1, PFM.game_state.level_max_limit)
      @exp = exp_list[lvl]
      @exp_rate = 0
      @level = lvl
    end

    # Check if the Pokemon can evolve and return the evolve id if possible
    # @param reason [Symbol] evolve check reason (:level_up, :trade, :stone)
    # @param extend_data [Hash, nil] extend_data generated by an item
    # @return [Array<Integer, nil>, false] if the Pokemon can evolve, the evolve id, otherwise false
    def evolve_check(reason = :level_up, extend_data = nil)
      return false if item_db_symbol == :everstone

      data = Configs.settings.always_use_form0_for_evolution ? primary_data : self.data

      if data.evolutions.empty?
        data = primary_data if Configs.settings.use_form0_when_no_evolution_data
        return false if data.evolutions.empty?
      end

      required_criterion = Pokemon.evolution_reason_required_criteria[reason] || []
      criteria = Pokemon.evolution_criteria

      expected_evolution = data.evolutions.find do |evolution|
        next false unless required_criterion.all? { |key| evolution.condition_data(key) }

        next evolution.conditions.all? do |condition|
          next false unless (block = criteria[condition[:type]])

          next instance_exec(condition[:value], extend_data, reason, &block)
        end
      end

      return false unless expected_evolution

      return data_creature(expected_evolution.db_symbol).id, expected_evolution.form
    end
    # Exchanged with another pokemon
    add_evolution_criteria(:tradeWith, [:tradeWith]) { |value, extend_data, reason| extend_data&.db_symbol == value && reason == :tradeWith }
    # Minimum level
    add_evolution_criteria(:minLevel) { |value| @level >= value.to_i }
    # Maximum level
    add_evolution_criteria(:maxLevel) { |value| @level <= value.to_i }
    # Holding an item
    add_evolution_criteria(:itemHold) { |value| value == item_db_symbol }
    # Minimum loyalty
    add_evolution_criteria(:minLoyalty) { |value| @loyalty >= value.to_i }
    # Maximum loyalty
    add_evolution_criteria(:maxLoyalty) { |value| @loyalty <= value.to_i }
    # Move 1
    add_evolution_criteria(:skill1) { |value| skill_learnt?(value) }
    # Move 2
    add_evolution_criteria(:skill2) { |value| skill_learnt?(value) }
    # Move 3
    add_evolution_criteria(:skill3) { |value| skill_learnt?(value) }
    # Move 4
    add_evolution_criteria(:skill4) { |value| skill_learnt?(value) }
    # On specific weather
    add_evolution_criteria(:weather) { |value| $env.current_weather_db_symbol == value }
    # Being on a specfic tag
    add_evolution_criteria(:env) { |value| $game_player.system_tag == value }
    # Having a specific gender
    add_evolution_criteria(:gender) { |value| @gender == value }
    # Evolving from stone
    add_evolution_criteria(:stone, [:stone]) { |value, extend_data, reason| reason == :stone && value == extend_data }
    # Evolving on a specific day/night cycle
    add_evolution_criteria(:dayNight) { |value| value == $game_variables[Yuki::Var::TJN_Tone] }
    # On a function call
    add_evolution_criteria(:func) { |value| send(value) }
    # Being on a specific map
    add_evolution_criteria(:maps) { |value| value.include?($game_map.map_id) }
    # Being traded
    add_evolution_criteria(:trade, [:trade]) { |_value, _extend_data, reason| reason == :trade }
    # ID field auto validation
    add_evolution_criteria(:id) { true }
    # FORM field auto validation
    add_evolution_criteria(:form) { true }
    # On a specific switch
    add_evolution_criteria(:switch) { |value| $game_switches[value] }
    # Having a specific nature
    add_evolution_criteria(:nature) { |value| nature_id == value }
    # Holding a gem to mega evolve
    add_evolution_criteria(:gemme) { false }

    # Method that actually make a Pokemon evolve
    # @param id [Integer] ID of the Pokemon that evolve
    # @param form [Integer, nil] form of the Pokemon that evolve
    def evolve(id, form)
      old_evolution_db_symbol = db_symbol
      old_evolution_form = self.form
      hp_diff = self.max_hp - self.hp
      self.id = id
      if form
        self.form = form
      else
        form_calibrate(:evolve)
      end
      return unless $actors.include?(self) # Don't do te rest if the pokemon isn't in the current party

      # evolution_items = (data.special_evolution || []).map { |hash| hash[:item_hold] || 0 }
      previous_pokemon_evolution_method = data_creature_form(old_evolution_db_symbol, old_evolution_form).evolutions
      evolution_items = previous_pokemon_evolution_method.map { |evolution| evolution.condition_data(:itemHold) }.compact
      self.item_holding = 0 if evolution_items.include?(item_db_symbol)
      # Normal skill learn
      check_skill_and_learn
      # Evolution skill learn
      check_skill_and_learn(false, 0)
      # Pokedex register (self is used to be sure we get the right information)
      $pokedex.mark_seen(self.id, self.form, forced: true)
      $pokedex.mark_captured(self.id)
      $pokedex.increase_creature_caught_count(self.id)
      # Refresh hp
      self.hp = (self.max_hp - hp_diff) if self.hp > 0
      exec_hooks(PFM::Pokemon, :evolution, binding)
    end

    # Add Shedinja evolution
    Hooks.register(PFM::Pokemon, :evolution, 'Shedinja Evolution') do
      next unless id == 291 && $actors.size < 6 && $bag.contain_item?(4)

      # @type [PFM::Pokemon]
      munja = dup
      munja.id = 292
      munja.hp = munja.max_hp
      munja.item_holding = 0
      $actors << munja
      $bag.remove_item(4, 1)
      $pokedex.mark_seen(292, forced: true)
      $pokedex.mark_captured(292)
    end

    # Change the id of the Pokemon
    # @param new_id [Integer] the new id of the Pokemon
    def id=(new_id)
      @character = nil
      if new_id && (req = data_creature(new_id)).id != 0 && (forms = req.forms)
        @id = new_id
        @db_symbol = forms.first.db_symbol
        @form = 0 if forms.none? { |creature_form| creature_form.form == @form }
        @form = form_generation(-1) if @form == 0
        @form = 0 if forms.none? { |creature_form| creature_form.form == @form }
        update_ability
      end
    end

    # Update the Pokemon Ability
    def update_ability
      return unless @ability_index

      @ability = get_data.abilities[@ability_index.to_i]
    end

    # Check evolve condition to evolve in Hitmonlee (kicklee)
    # @return [Boolean] if the condition is valid
    def elv_kicklee
      atk > dfe
    end

    # Check evolve condition to evolve in Hitmonchan (tygnon)
    # @return [Boolean] if the condition is valid
    def elv_tygnon
      atk < dfe
    end

    # Check evolve condition to evolve in Hitmontop (Kapoera)
    # @return [Boolean] if the condition is valid
    def elv_kapoera
      atk == dfe
    end

    # Check evolve condition to evolve in Silcoon (Armulys)
    # @return [Boolean] if the condition is valid
    def elv_armulys
      ((@code & 0xFFFF) % 10) <= 4
    end

    # Check evolve condition to evolve in Cascoon (Blindalys)
    # @return [Boolean] if the condition is valid
    def elv_blindalys
      !elv_armulys
    end

    # Check evolve condition to evolve in Mantine
    # @return [Boolean] if the condition is valid
    def elv_demanta
      PFM.game_state.has_pokemon?(223)
    end

    # Check evolve condition to evolve in Pangoro (Pandarbare)
    # @return [Boolean] if the condition is valid
    def elv_pandarbare
      return $actors.any? { |pokemon| pokemon&.type_dark? }
    end

    # Check evolve condition to evolve in Malamar (Sepiatroce)
    # @note uses :DOWN to validate the evolve condition
    # @return [Boolean] if the condition is valid
    def elv_sepiatroce
      return Input.press?(:DOWN)
    end

    # Check evolve condition to evolve in Sylveon (Nymphali)
    # @return [Boolean] if the condition is valid
    def elv_nymphali
      return @skills_set.any? { |skill| skill&.type?(data_type(:fairy).id) }
    end

    # Check evolve condition to evolve in Toxtricity-amped (Salarsen-aigüe)
    # [0, 2, 3, 4, 6, 8, 9, 11, 13, 14, 19, 22, 24]
    # return [Boolean] if the condition is valid
    def elv_toxtricity_amped
      natures_toxtricity = %i[hardy brave adamant naughty docile impish lax hasty jolly naive rash sassy quirky]
      return natures_toxtricity.include?(Configs.natures.db_symbol_to_id.key(nature_id))
    end

    # Check evolve condition when not in Toxtricity-amped (Salarsen-aigüe)
    def elv_toxtricity_low_key
      return !elv_toxtricity_amped
    end

    # Check evolve condition for 99% of creatures
    # @return [Boolean] if the condition is valid
    def elv_99percent
      return ((@code & 0xFFFF) % 100) <= 99
    end

    # Check evolve condition for 1% of creatures
    # @return [Boolean] if the condition is valid
    def elv_1percent
      return !elv_99percent
    end
  end
end
