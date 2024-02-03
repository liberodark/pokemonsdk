module PFM
  # Daycare management system
  #
  # The global Daycare manager is stored in $daycare and PFM.game_state.daycare
  # @author Nuri Yuri
  #
  # Daycare data Hash format
  #   pokemon: Array # The list of Pokemon in the daycare (PFM::Pokemon or nil)
  #   level: Array # The list of level the Pokemon had when sent to the daycare
  #   layable: Integer # ID of the Pokemon that can be in the egg
  #   rate: Integer # Chance the egg can be layed
  #   egg: Boolean # If an egg has been layed
  class Daycare
    # Only use the FIRST FORM for breed groups
    USE_FIRST_FORM_BREED_GROUPS = false
    # Specific form handler (system that can force a for according to a code)
    SPECIFIC_FORM_HANDLER = {
      myfakepokemon: proc { |_mother, _father| next(rand(10)) } # Returns a random form between 0 and 9
    }
    # List of Pokemon that cannot breed (event if the conditions are valid)
    NOT_BREEDING = %i[phione manaphy]
    # List of Pokemon that only breed with Ditto
    BREEDING_WITH_DITTO = %i[phione manaphy]
    # ID of the Ditto group
    DITTO_GROUP = 13
    # ID of the breed group that forbid breeding
    NOT_BREEDING_GROUP = 15
    # List of price rate for all daycare
    # @return [Hash{Integer => Integer}]
    PRICE_RATE = Hash.new(100)
    # Egg rate according to the common group, common OT, oval_charm (dig(common_group?, common_OT?, oval_charm?))
    EGG_RATE = [
      [ # No Common Group
        [50, 80], # No Common OT. [no_oval_charm, oval_charm]
        [20, 40]  # Common OT. [no_oval_charm, oval_charm]
      ],
      [ # Common Group
        [70, 88], # No Common OT. [no_oval_charm, oval_charm]
        [50, 80]  # Common OT. [no_oval_charm, oval_charm]
      ]
    ]
    # "Female" breeder that can have different baby (non-incense condition)
    # @return [Hash{Symbol => Array}]
    BABY_VARIATION = {
      nidoranf: nidoran = %i[nidoranf nidoranm],
      nidoranm: nidoran,
      volbeat: volbeat = %i[volbeat illumise],
      illumise: volbeat,
      tauros: tauros = %i[tauros miltank],
      miltank: tauros
    }
    # Structure holding the information about the insence the male should hold
    # and the baby that will be generated
    IncenseInfo = Struct.new(:incense, :baby)
    # "Female" that can have different baby if the male hold an incense
    INCENSE_BABY = {
      marill: azurill = IncenseInfo.new(:sea_incense, :azurill),
      azumarill: azurill,
      wobbuffet: IncenseInfo.new(:lax_incense, :wynaut),
      roselia: budew = IncenseInfo.new(:rose_incense, :budew),
      roserade: budew,
      chimecho: IncenseInfo.new(:pure_incense, :chingling),
      sudowoodo: IncenseInfo.new(:rock_incense, :bonsly),
      mr_mime: mime_jr = IncenseInfo.new(:odd_incense, :mime_jr),
      mr_rime: mime_jr,
      chansey: happiny = IncenseInfo.new(:luck_incense, :happiny),
      blissey: happiny,
      snorlax: IncenseInfo.new(:full_incense, :munchlax),
      mantine: IncenseInfo.new(:wave_incense, :mantyke)
    }
    # Non inherite balls
    NON_INHERITED_BALL = %i[master_ball cherish_ball]
    # IV setter list
    IV_SET = %i[iv_hp= iv_dfe= iv_atk= iv_spd= iv_ats= iv_dfs=]
    # IV getter list
    IV_GET = %i[iv_hp iv_dfe iv_atk iv_spd iv_ats iv_dfs]
    # List of power item that transmit IV in the same order than IV_GET/IV_SET
    IV_POWER_ITEM = %i[power_weight power_belt power_bracer power_anklet power_lens power_band]

    # Get the game state responsive of the whole game state
    # @return [PFM::GameState]
    attr_accessor :game_state

    # Create the daycare manager
    # @param game_state [PFM::GameState] variable responsive of containing the whole game state for easier access
    def initialize(game_state = PFM.game_state)
      @daycares = []
      @game_state = game_state
    end

    # Update every daycare
    def update
      check_egg = should_check_eggs?
      @daycares.each do |daycare|
        next unless daycare
        daycare[:pokemon].each { |pokemon| exp_pokemon(pokemon) }
        try_to_lay(daycare) if check_egg && (daycare[:layable] || 0) != 0
      end
    end

    # Store a Pokemon to a daycare
    # @param id [Integer] the ID of the daycare
    # @param pokemon [PFM::Pokemon] the pokemon to store in the daycare
    # @return [Boolean] if the pokemon could be stored in the daycare
    def store(id, pokemon)
      @daycares[id] ||= { pokemon: [], level: [], layable: 0, rate: 0, egg: nil }
      return false if full?(id)

      daycare = @daycares[id]
      daycare[:level][daycare[:pokemon].size] = pokemon.level
      daycare[:pokemon] << pokemon
      layable_check(daycare, daycare[:pokemon]) if daycare[:pokemon].size == 2
      log_debug "==== Pension Infos ====\nRate : #{daycare[:rate]}%\nPokémon : #{text_get(0, daycare[:layable])}\n"
      return true
    end

    # Price to pay in order to withdraw a Pokemon
    # @param id [Integer] the ID of the daycare
    # @param index [Integer] the index of the Pokemon in the daycare
    # @return [Integer] the price to pay
    def price(id, index)
      return 0 unless (pokemon = @daycares.dig(id, :pokemon, index))
      return PRICE_RATE[id] * (pokemon.level - @daycares.dig(id, :level, index) + 1)
    end

    # Get a Pokemon information in the daycare
    # @param id [Integer] the ID of the daycare
    # @param index [Integer] the index of the Pokemon in the daycare
    # @param prop [Symbol] the method to call of PFM::Pokemon to get the information
    # @param args [Array] the list of arguments of the property
    # @return [Object] the result
    def get_pokemon(id, index, prop, *args)
      return nil unless (pokemon = @daycares.dig(id, :pokemon, index))
      return pokemon.send(prop, *args)
    end

    # Withdraw a Pokemon from a daycare
    # @param id [Integer] the ID of the daycare
    # @param index [Integer] the index of the Pokemon in the daycare
    # @return [PFM::Pokemon, nil]
    def retrieve_pokemon(id, index)
      return nil unless (daycare = @daycares[id]) && (pokemon = daycare.dig(:pokemon, index))

      daycare[:pokemon][index] = nil
      daycare[:level][index] = nil
      daycare[:pokemon].compact!
      daycare[:level].compact!
      daycare[:rate] = 0
      daycare[:layable] = 0
      return pokemon
    end
    alias withdraw_pokemon retrieve_pokemon
    alias retreive_pokemon retrieve_pokemon

    # Get the egg rate of a daycare
    # @param id [Integer] the ID of the daycare
    # @return [Integer]
    def retrieve_egg_rate(id)
      return @daycares[id][:rate].to_i
    end
    alias retreive_egg_rate retrieve_egg_rate

    # Retrieve the egg layed
    # @param id [Integer] the ID of the daycare
    # @return [PFM::Pokemon]
    def retrieve_egg(id)
      daycare = @daycares[id]
      daycare[:egg] = nil
      layable_check(daycare, daycare[:pokemon])
      log_debug "==== Pension Infos ====\nRate : #{daycare[:rate]}%\nPokémon : #{text_get(0, daycare[:layable])}\n"
      pokemon = PFM::Pokemon.new(daycare[:layable], 1)
      inherit(pokemon, daycare[:pokemon])
      pokemon.hp = pokemon.max_hp
      pokemon.egg_init
      pokemon.memo_text = [28, 31]
      return pokemon
    end
    alias retreive_egg retrieve_egg

    # If an egg was layed in this daycare
    # @param id [Integer] the ID of the daycare
    # @return [Boolean]
    def layed_egg?(id)
      return @daycares.dig(id, :egg) == true
    end
    alias has_egg? layed_egg?

    # If a daycare is full
    # @param id [Integer] the ID of the daycare
    # @return [Boolean]
    def full?(id)
      return false unless (pokemon_list = @daycares.dig(id, :pokemon))

      return pokemon_list.size > 1
    end

    # If a daycare is empty
    # @param id [Integer] the ID of the daycare
    # @return [Boolean]
    def empty?(id)
      return @daycares.dig(id, :pokemon).empty?
    end

    # Parse the daycare Pokemon text info
    # @param var_id [Integer] ID of the game variable where the ID of the daycare is stored
    # @param index [Integer] index of the Pokemon in the daycare
    def parse_poke(var_id, index)
      # @type [PFM::Pokemon]
      pokemon = @daycares.dig(game_state.game_variables[var_id], :pokemon, index)
      (text = PFM::Text).set_num3(pokemon.level_text)
      text.set_num3(pokemon.level_text, 1)
      text.set_pkname(pokemon.name)
      parse_text(36, 33 + (pokemon.gender == 0 ? 3 : pokemon.gender))
    end

    private

    # Check the layability of a daycare
    # @param daycare [Hash] the daycare informations Hash
    # @param parents [Array] the list of Pokemon in the daycar
    def layable_check(daycare, parents)
      # @type [PFM::Pokemon]
      male, female = assign_gender(*parents)
      rate = perform_simple_rate_calculation(male, female)
      daycare[:rate] = rate
      # If there's a change to breed, we try to find the right baby using the special lay check
      if rate != 0
        return if special_lay_check(daycare, female, male)

        # @type [Studio::CreatureForm]
        *, female_data = get_pokemon_data(male, female)
        daycare[:layable] = data_creature(female_data.baby_db_symbol).id
        daycare[:rate] = 0 if daycare[:layable] == 0
      else
        daycare[:layable] = 0
      end
    end

    # Special check to lay an egg
    # @param daycare [Hash] the daycare information
    # @param female [PFM::Pokemon] the female
    # @param male [PFM::Pokemon] the male
    # @return [Integer, false] the id of the Pokemon that will be in the egg or no special baby with these Pokemon
    def special_lay_check(daycare, female, male)
      female_sym = female.db_symbol
      male_sym = male.db_symbol
      # Ditto + (Phione / Manaphy)
      if male.db_symbol == :ditto && BREEDING_WITH_DITTO.include?(female_sym)
        return daycare[:layable] = data_creature(:phione).id
      elsif NOT_BREEDING.include?(female_sym) || NOT_BREEDING.include?(male_sym)
        daycare[:layable] = 0
        return daycare[:rate] = 0
      end
      # @type [Array<Symbol>] list of baby the Pokemon can breed
      if (variable_baby = BABY_VARIATION[female_sym])
        return daycare[:layable] = data_creature(variable_baby.sample).id
      end
      # @type [IncenseInfo]
      if (insence_info = INCENSE_BABY[female_sym]) && (male.item_db_symbol == insence_info.incense || female.item_db_symbol == insence_info.incense)
        return daycare[:layable] = data_creature(insence_info.baby).id
      end

      return false
    end

    # Give 1 exp point to a pokemon
    # @param pokemon [PFM::Pokemon] the pokemon to give one exp point
    def exp_pokemon(pokemon)
      return if pokemon.level >= PFM.game_state.level_max_limit

      pokemon.exp += 1
      if pokemon.exp >= pokemon.exp_lvl
        pokemon.level_up_stat_refresh
        pokemon.check_skill_and_learn(true)
        log_debug "==== Pension Infos ====\nLevelUp : #{pokemon.given_name}\n"
      end
    end

    # Attempt to lay an egg
    # @param daycare [Hash] the daycare informations Hash
    def try_to_lay(daycare)
      return if daycare[:egg]

      daycare[:egg] = true if rand(100) < daycare[:rate]
      log_debug "==== Pension Infos ====\nLay attempt : #{!daycare[:egg] ? 'Failure' : 'Success'}\n"
    end

    # Make the pokemon inherit the gene of its parents
    # @param pokemon [PFM::Pokemon] the pokemon
    # @param parents [Array(PFM::Pokemon, PFM::Pokemon)] the parents
    def inherit(pokemon, parents)
      # @type [PFM::Pokemon]
      male, female = assign_gender(*parents)

      # Inherit sequence
      unless NON_INHERITED_BALL.include?(data_item(female.captured_with).db_symbol)
        pokemon.captured_with = female.captured_with
      end

      inherit_form(pokemon, female, male)
      inherit_nature(pokemon, female, male)
      inherit_ability(pokemon, female)
      inherit_moves(pokemon, male, female)
      inherit_iv(pokemon, male, female)
    end

    # Tell if the system should check for eggs in this update
    # @return [Boolean]
    def should_check_eggs?
      (PFM.game_state.steps & 0xFF) == 0
    end

    # Return the parents in male, female order (to make the lay process easier)
    # @param potential_male [PFM::Pokemon]
    # @param potential_female [PFM::Pokemon]
    # @return [Array<PFM::Pokemon>]
    def assign_gender(potential_male, potential_female)
      # If the potential male is a female, potential_female is a male
      # If the potential_female is a ditto, potential_male will be the mother
      if potential_male.gender == 2 || potential_female.db_symbol == :ditto
        potential_male, potential_female = potential_female, potential_male
      end
      # Otherwise potential_male is a "male" and potential_female is a "female"
      return potential_male, potential_female
    end

    # Return the data of each breedable Pokemon
    # @param male [PFM::Pokemon]
    # @param female [PFM::Pokemon]
    # @return [Array<Studio::CreatureForm>]
    def get_pokemon_data(male, female)
      return male.data, female.data unless USE_FIRST_FORM_BREED_GROUPS

      return male.primary_data, female.primary_data
    end

    # Return the egg rate (% chance of having an egg)
    # @param male [PFM::Pokemon]
    # @param female [PFM::Pokemon]
    # @return [Integer]
    def perform_simple_rate_calculation(male, female)
      return 0 if male.gender != 0 && male.gender == female.gender
      return 0 if male.db_symbol == :ditto && female.db_symbol == :ditto

      # @type [Studio::CreatureForm]
      male_data, female_data = get_pokemon_data(male, female)
      return 0 if male_data.breed_groups.include?(NOT_BREEDING_GROUP) || female_data.breed_groups.include?(NOT_BREEDING_GROUP)

      common_in_group = (female_data.breed_groups - (female_data.breed_groups - male_data.breed_groups)).uniq
      return 0 unless check_group_compatibility(common_in_group, male_data, female_data)

      common_ot = male.trainer_id == female.trainer_id
      oval_charm = game_state.bag.contain_item?(:oval_charm)
      return EGG_RATE.dig(common_in_group.any?.to_i, common_ot.to_i, oval_charm.to_i) || 0
    end

    # Return if the parents breed groupes are compatible
    # @param common_in_group [Array]
    # @param male_data [Studio::CreatureForm]
    # @param female_data [Studio::CreatureForm]
    # @return [Boolean]
    def check_group_compatibility(common_in_group, male_data, female_data)
      return true if male_data.breed_groups.include?(DITTO_GROUP) || female_data.breed_groups.include?(DITTO_GROUP)
      return false if common_in_group.empty?

      return true
    end

    # Make the pokemon inherit its form
    # @param pokemon [PFM::Pokemon]
    # @param female [PFM::Pokemon]
    # @param male [PFM::Pokemon]
    def inherit_form(pokemon, female, male)
      baby_form = data_creature_form(female.db_symbol, female.form).baby_form
      if (handler = SPECIFIC_FORM_HANDLER[pokemon.db_symbol])
        pokemon.form = handler.call(female, male) || baby_form
        return
      end
      pokemon.form = baby_form
    end

    # Make the pokemon inherit its nature
    # @param pokemon [PFM::Pokemon]
    # @param female [PFM::Pokemon]
    # @param male [PFM::Pokemon]
    def inherit_nature(pokemon, female, male)
      if male.item_db_symbol == :everstone && female.item_db_symbol == :everstone
        pokemon.nature = rand(100) < 50 ? male.nature_id : female.nature_id
      else
        pokemon.nature = male.nature_id if male.item_db_symbol == :everstone
        pokemon.nature = female.nature_id if female.item_db_symbol == :everstone
      end
    end

    # Make the Pokemon inherit the female ability
    # If the ability is the hidden one, it'll have 60% chance, otherwise 80% chance
    # @param pokemon [PFM::Pokemon]
    # @param female [PFM::Pokemon]
    def inherit_ability(pokemon, female)
      ability = female.ability_db_symbol
      chances = female.data.abilities.index(ability) == 2 ? 60 : 80
      if rand(100) < chances
        # The female ability is inherited, we use its ability slot
        pokemon.ability_index = female.data.abilities.index(ability)
        pokemon.update_ability
      end
    end

    # Make the Pokemon inherit the parents moves
    # @param pokemon [PFM::Pokemon]
    # @param male [PFM::Pokemon]
    # @param female [PFM::Pokemon]
    def inherit_moves(pokemon, male, female)
      female_moveset = female.data.move_set.select(&:level_learnable?).map(&:move)
      male_moveset = male.data.move_set.select(&:level_learnable?).map(&:move)
      pokemon_moveset = pokemon.data.move_set.select(&:level_learnable?).map(&:move)
      # Take moves known by male, female & pokemon
      common_skill = female_moveset - (female_moveset - male_moveset)
      common_skill = pokemon_moveset - (pokemon_moveset - common_skill)
      # Try to teach all the skill both parents know and have in common with baby
      common_skill.each do |move|
        next unless female.skill_learnt?(move) && male.skill_learnt?(move)

        learn_skill(pokemon, move)
      end
      breed_moves = pokemon.data.move_set.select(&:breed_learnable?).map(&:move)
      # Try to teach all the breed move known by the male or female
      breed_moves.each do |move|
        next unless male.skill_learnt?(move) || female.skill_learnt?(move)

        learn_skill(pokemon, move)
      end
      # Try to teach Volt Tackle
      learn_volt_tackle(pokemon, male, female)
    end

    # Teach a skill to the Pokemon
    # @param pokemon [PFM::Pokemon]
    # @param skill_id [Integer, Symbol] ID of the skill in the database
    def learn_skill(pokemon, skill_id)
      return unless pokemon.learn_skill(skill_id).nil? # Skill learn with success or already learnt

      pokemon.skills_set.shift
      pokemon.learn_skill(skill_id)
    end

    # Try to teach Volt Tackle to Pichu
    # @param pokemon [PFM::Pokemon]
    # @param male [PFM::Pokemon]
    # @param female [PFM::Pokemon]
    def learn_volt_tackle(pokemon, male, female)
      return unless pokemon.db_symbol == :pichu
      return unless male.item_db_symbol == :light_ball || female.item_db_symbol == :light_ball

      learn_skill(pokemon, :volt_tackle)
    end

    # Inherit the IV
    # @param pokemon [PFM::Pokemon]
    # @param male [PFM::Pokemon]
    # @param female [PFM::Pokemon]
    def inherit_iv(pokemon, male, female)
      if female.item_db_symbol == :destiny_knot || male.item_db_symbol == :destiny_knot
        inherit_iv_destiny_knot(pokemon, male, female)
      else
        inherit_iv_regular(pokemon, male, female)
      end
      inherit_iv_power(pokemon, male, female)
    end

    # Inherit the IV when one of the parent holds the destiny knot.
    # It'll transmit 5 of the IV (of both parents randomly) to the child
    # @param pokemon [PFM::Pokemon]
    # @param parents [Array<PFM::Pokemon>]
    def inherit_iv_destiny_knot(pokemon, *parents)
      IV_GET.sample(5).each do |iv|
        setter = IV_SET[IV_GET.index(iv)]
        pokemon.send(setter, parents.sample.send(iv))
      end
    end

    # Regular IV inherit from parents.
    # 3 attempt to inherit the IV.
    #   The first attempt will give one of the IV of any parent
    #   The second will give one of the IV (excluding HP) of any parent
    #   The third will give one of the IV (excluding HP & DFE) of any parent
    # All attempt can overwrite the previous one (if the stat is the same)
    # @note This works thanks to the IV_GET & IV_SET constant configuration!
    # @param pokemon [PFM::Pokemon]
    # @param parents [Array<PFM::Pokemon>]
    def inherit_iv_regular(pokemon, *parents)
      iv_get = IV_GET.clone
      3.times do
        iv = iv_get.sample
        setter = IV_SET[IV_GET.index(iv)]
        pokemon.send(setter, parents.sample.send(iv))
        iv_get.shift # Remove :iv_hp and then :iv_dfe
      end
    end

    # IV inherit from parents holding power item
    # @param pokemon [PFM::Pokemon]
    # @param parents [Array<PFM::Pokemon>]
    def inherit_iv_power(pokemon, *parents)
      parents.each do |parent|
        next unless (iv_index = IV_POWER_ITEM.index(parent.item_db_symbol))
        pokemon.send(IV_SET[iv_index], parent.send(IV_GET[iv_index]))
      end
    end
  end

  class GameState
    # The daycare management object
    # @return [PFM::Daycare]
    attr_accessor :daycare

    on_player_initialize(:daycare) { @daycare = PFM.daycare_class.new(self) }
    on_expand_global_variables(:daycare) do
      # Variable containing the daycare information
      $daycare = @daycare
      @daycare.game_state = self
    end
  end
end

PFM.daycare_class = PFM::Daycare
