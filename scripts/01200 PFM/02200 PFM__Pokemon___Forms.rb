#encoding: utf-8

module PFM
  class Pokemon
    # Change the form of the Pokemon
    # @note If the form doesn't exist, the form is not changed
    # @param v [Integer] the new form index
    def form=(v)
      v = v.to_i
      if($game_data_pokemon[@id][v])
        @form=v
        form_calibrate
        update_ability
      end
    end
    # Check if the Pokemon can mega evolve
    # @return [Integer, false] form index if the Pokemon can mega evolve, false otherwise
    def can_mega_evolve?
      data = $game_data_pokemon[@id]
      item_id = @item_holding
      if(data.size > 30)
        30.step(data.size - 1) do |i|
          d = data[i]
          next unless d.special_evolution
          d.special_evolution.each do |j|
            next if j[:form] and j[:form] != @form
            return i if item_id == j[:gemme]
            return i if j[:mega_skill] and self.skill_learnt?(j[:mega_skill])
          end
        end
      end
      return false
    end
    # Mega evolve the Pokemon (if possible)
    def mega_evolve
      mega_evolution = can_mega_evolve?
      return unless mega_evolution
      @mega_evolved = [@form, @ability]
      @form = mega_evolution
      @ability_current = @ability = $game_data_pokemon[@id][@form].abilities[rand(3)]
    end
    # Reset the Pokemon to its normal form after mega evolution
    def unmega_evolve
      if @mega_evolved
        @form, @ability = @mega_evolved
        @ability_current = @ability
        @mega_evolved = false
      end
    end
    # Is the Pokemon mega evolved ?
    def mega_evolved?
      return @mega_evolved != false
    end
    # Automatically generate the form index of the Pokemon
    # @param id [Integer] ID of the Pokemon in the database
    # @param form [Integer] if form != 0 does not generate the form (protection)
    # @return [Integer] the form index
    def _form_generation(id, form)
      return form if form != -1
      @character = nil
      sym = db_symbol
      if(sym == :unown) #Zarbi
        return @code % 28
      elsif(sym == :castform) #Morphéo
        env = $env
        if(env.building? or env.normal?)
          return 0
        elsif(env.sunny?)
          return 2
        elsif(env.rain?)
          return 3
        elsif(env.hail?)
          return 6
        end
      elsif(sym == :burmy || sym == :wormadam)
        env = $env
        if(env.building?)
          return 2
        elsif(env.grass? or env.tall_grass? or env.very_tall_grass?)
          return 0
        else
          return 1
        end
      elsif(sym == :cherrim)
        return 1 if $env.sunny?
      elsif(sym == :deerling)
        time = Time.new
        case time.month
        when 1,2
          return 3
        when 3
          return time.day < 21 ? 3 : 0
        when 6
          return time.day < 21 ? 0 : 1
        when 7,8
          return 1
        when 9
          return time.day < 21 ? 1 : 2
        when 10,11
          return 2
        when 12
          return time.day < 21 ? 2 : 3
        end
      elsif(sym == :meowstic)
        return 1 if @gender == 2
      end
      return 0
    end
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
    # Automatically calibrate the form of the Pokemon
    # @return [Boolean] if the Pokemon's form has changed
    def form_calibrate
      @character = nil
      data = $game_data_pokemon[@id]
      last_form = @form
      sym = db_symbol
      case sym
      when :giratina #> Giratina
        @form = item_db_symbol == :griseous_orb ? 1 : 0
      when :arceus #> Arceus
        @form = ArceusItem.index(item_db_symbol).to_i
      when :shaymin #> Shaymin
        @form = (item_db_symbol == :gracidea) && !($env.night? || $env.sunset?) ? 1 : 0
      when :genesect #> Genesect
        @form = GenesectModules.index(item_db_symbol).to_i
      when :silvally #> Silvallié
        @form = SilvallyROM.index(item_db_symbol).to_i
      end
      #>Correction de la forme en cas d'erreur de BDD
      @form = 0 unless data[@form]
      #>Récupération du talent propre à la forme
      @current_ability = @ability = data[@form].abilities[data[last_form].abilities.index(@ability).to_i]
      return last_form != @form
    end
  end
end
