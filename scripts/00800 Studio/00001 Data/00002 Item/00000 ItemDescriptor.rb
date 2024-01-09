module PFM
  # Module that help item to be used by returning an "extend_data" that every interface can understand
  #   Structure of the extend_data returned
  #     no_effect: opt Boolean # The item has no effect
  #     chen: opt Boolean # The stalker also called Prof. CHEN that tells you the item cannot be used there
  #     open_party: opt Boolean # If the item require the Party menu to be opened in selection mode
  #     on_creature_choice: opt Proc # The proc to check when the player select a Pokemon(parameter) (return a value usefull to the interface)
  #     on_creature_use: opt Proc # The proc executed on a Pokemon(parameter) when the item is used
  #     open_skill: opt Boolean # If the item require the Skill selection interface to be open
  #     open_skill_learn: opt Integer # ID of the skill to learn if the item require to Open the Skill learn interface
  #     on_skill_choice: opt Proc # Proc to call to validate the choice of the skill(parameter)
  #     on_skill_use: opt Proc # Proc to call when a skill(parameter) is validated and choosen 
  #     on_use: opt Proc # The proc to call when the item is used.
  #     action_to_push: opt Proc # The proc to call to push the specific action when the item is used in battle
  #     stone_evolve: opt Boolean # If a Pokemon evolve by stone
  #     use_before_telling: opt Boolean # If :on_use proc is called before telling the item is used
  #     skill_message_id: opt Integer # ID of the message to show in the win_text in the Summary
  #
  # @author Nuri Yuri
  module ItemDescriptor
    include GameData::SystemTags
    # Sound played when a Pokemon levels up
    LVL_SOUND = 'audio/me/rosa_levelup'
    # Proc executed when there's no condition (returns true)
    NO_CONDITION = proc { true }
    # Common event condition procs to call before calling event (common_event_id => proc { conditions })
    COMMON_EVENT_CONDITIONS = Hash.new(NO_CONDITION)
    # Fallback for old users
    CommonEventConditions = COMMON_EVENT_CONDITIONS
    # No effect Hash descriptor
    NO_EFFECT = { no_effect: true }
    # You cannot use this item here Hash descriptor
    CHEN = { chen: true }
    # Stage boost method Symbol in PFM::Pokemon
    BOOST = %i[change_atk change_dfe change_spd change_ats change_dfs change_eva change_acc]
    # Message text id of the various item heals (index => text_id)
    BagStatesHeal = [116, 110, 111, 112, 120, 113, 116, 116, 110]
    # Message text id of the various EV change (index => text_id)
    EVStat = [134, 129, 130, 133, 131, 132]
    # Constant containing all the default extend_data
    # @return [Hash{ Class => Wrapper }]
    EXTEND_DATAS = Hash.new { Wrapper.new }
    # Constant containing all the chen prevention
    CHEN_PREVENTIONS = {}

    module_function

    # Describe an item with a Hash descriptor
    # @param item_id [Integer] ID of the item in the database
    # @return [Wrapper] the Wrapper helping to use the item
    def actions(item_id)
      item = data_item(item_id)
      # @type [Wrapper]
      wrapper = (EXTEND_DATAS.key?(item.db_symbol) ? EXTEND_DATAS[item.db_symbol] : EXTEND_DATAS[item.class]).dup
      wrapper.item = item
      wrapper.stone_evolve = item.is_a?(Studio::StoneItem)
      wrapper.open_skill_learn = item.is_a?(Studio::TechItem) ? Studio::TechItem.from(item).move_db_symbol : nil
      wrapper.no_effect = item.db_symbol == :__undef__
      wrapper.void_non_battle_block if $game_temp.in_battle
      return wrapper if wrapper.no_effect

      chen = CHEN_PREVENTIONS[item.db_symbol] || CHEN_PREVENTIONS[item.class]
      wrapper.chen = chen&.call(item)
      wrapper.chen = true unless $game_temp.in_battle ? item.is_battle_usable : item.is_map_usable
      return wrapper
    end

    # Define an event condition
    # @param event_id [Integer] ID of the common event that will be called if the condition validates
    # @yieldreturn [Boolean] if the event can be called
    def define_event_condition(event_id, &block)
      COMMON_EVENT_CONDITIONS[event_id] = block || NO_CONDITION
    end

    # Define a usage of item from the bag
    # @param klass [Class<Studio::Item>, Symbol] class or db_symbol of the item
    # @param use_before_telling [Boolean] if the item should be used before showing the message
    # @yieldparam item [Studio::Item] item used
    # @yieldparam scene [GamePlay::Base]
    # @yieldreturn [:unused] if block returns :unused, the item is considered as not used and not consumed
    def define_bag_use(klass, use_before_telling = false, &block)
      raise 'Block is mandatory' unless block_given?

      EXTEND_DATAS[klass] = wrapper = Wrapper.new
      wrapper.on_use = block
      wrapper.use_before_telling = use_before_telling
    end

    # Define a chen prevention for an item (It's not time to use this item)
    # @param klass [Class<Studio::Item>, Symbol] class or db_symbol of the item
    # @yieldparam item [Studio::Item] item used
    # @yieldreturn [Boolean] if chen tells it's not time for that!
    def define_chen_prevention(klass, &block)
      CHEN_PREVENTIONS[klass] = block
    end

    # Define if an item can be used on a specific Pokemon
    # @param klass [Class<Studio::Item>, Symbol] class or db_symbol of the item
    # @yieldparam item [Studio::Item] item used
    # @yieldparam creature [PFM::Pokemon] creature that should be tested
    # @yieldreturn [Boolean] if the item can be used on the Pokemon
    def define_on_creature_usability(klass, &block)
      raise 'Block is mandatory' unless block_given?

      wrapper = EXTEND_DATAS[klass]&.open_party ? EXTEND_DATAS[klass] : Wrapper.new
      wrapper.open_party = true
      wrapper.on_creature_choice = block
      EXTEND_DATAS[klass] = wrapper
    end

    # Define the actions performed on a Pokemon on map
    # @param klass [Class<Studio::Item>, Symbol] class or db_symbol of the item
    # @yieldparam item [Studio::Item] item used
    # @yieldparam creature [PFM::Pokemon]
    # @yieldparam scene [GamePlay::Base]
    # @yieldreturn [Boolean] if the item can be used on the Pokemon
    def define_on_creature_use(klass, &block)
      raise 'Block is mandatory' unless block_given?
      raise 'Please use define_on_creature_usability before' unless EXTEND_DATAS[klass]&.open_party

      EXTEND_DATAS[klass].on_creature_use = block
    end

    # Define the actions performed on a Pokemon in battle
    # @param klass [Class<Studio::Item>, Symbol] class or db_symbol of the item
    # @yieldparam item [Studio::Item] item used
    # @yieldparam creature [PFM::Pokemon]
    # @yieldparam scene [Battle::Scene]
    # @yieldreturn [Boolean] if the item can be used on the Pokemon
    def define_on_creature_battler_use(klass, &block)
      raise 'Block is mandatory' unless block_given?
      raise 'Please use define_on_creature_usability before' unless EXTEND_DATAS[klass]&.open_party

      EXTEND_DATAS[klass].action_to_push = block
    end

    # Define if an item can be used on a specific Move
    # @param klass [Class<Studio::Item>, Symbol] class or db_symbol of the item
    # @param skill_message_id [Integer, nil] ID of the message shown in the summary UI
    # @yieldparam item [Studio::Item] item used
    # @yieldparam skill [PFM::Skill] skill that should be tested
    # @yieldparam scene [Battle::Scene]
    # @yieldreturn [Boolean] if the item can be used on the Pokemon
    def define_on_move_usability(klass, skill_message_id = nil, &block)
      raise 'Block is mandatory' unless block_given?
      raise 'Please use define_on_creature_usability before' unless EXTEND_DATAS[klass]&.open_party

      (wrapper = EXTEND_DATAS[klass]).open_skill = true
      wrapper.skill_message_id = skill_message_id
      wrapper.on_skill_choice = block
    end

    # Define the actions of the item on a specific move on map
    # @param klass [Class<Studio::Item>, Symbol] class or db_symbol of the item
    # @yieldparam item [Studio::Item] item used
    # @yieldparam creature [PFM::Pokemon]
    # @yieldparam skill [PFM::Skill]
    # @yieldparam scene [Battle::Scene]
    # @yieldreturn [Boolean] if the item can be used on the Pokemon
    def define_on_move_use(klass, &block)
      raise 'Block is mandatory' unless block_given?
      raise 'Please use define_on_move_usability before' unless EXTEND_DATAS[klass]&.open_skill

      EXTEND_DATAS[klass].on_skill_use = block
    end

    # Define the actions of the item on a specific move in battle
    # @param klass [Class<Studio::Item>, Symbol] class or db_symbol of the item
    # @yieldparam item [Studio::Item] item used
    # @yieldparam creature [PFM::Pokemon]
    # @yieldparam skill [PFM::Skill]
    # @yieldparam scene [Battle::Scene]
    # @yieldreturn [Boolean] if the item can be used on the Pokemon
    def define_on_battle_move_use(klass, &block)
      raise 'Block is mandatory' unless block_given?
      raise 'Please use define_on_move_usability before' unless EXTEND_DATAS[klass]&.open_skill

      EXTEND_DATAS[klass].action_to_push = block
    end

    # Wrapper to make the item description more usefull
    class Wrapper
      # Get if the item has no effect
      # @return [Boolean]
      attr_accessor :no_effect
      # Get if the item should not be used there
      # @return [Boolean]
      attr_accessor :chen
      # Get if the item should open the party menu
      # @return [Boolean]
      attr_accessor :open_party
      # Get if the item should open the skill menu
      # @return [Boolean]
      attr_accessor :open_skill
      # Get the ID of the move that should be learnt if it should be learnt
      # @return [Integer, nil]
      attr_accessor :open_skill_learn
      # Get if the item is making a Pokemon evolve
      # @return [Boolean]
      attr_accessor :stone_evolve
      # Get if the item should be used before the usage message
      # @return [Boolean]
      attr_accessor :use_before_telling
      # Get the item bound to this wrapper
      # @return [Studio::Item]
      attr_accessor :item
      # Get the skill bound to the wrapper
      # @return [PFM::Skill]
      attr_reader :skill
      # Get the ID of the message that should be shown in the Summary UI
      # @return [Integer, nil]
      attr_accessor :skill_message_id
      # Register the on_creature_choice block
      attr_writer :on_creature_choice
      # Register the on_creature_use block
      attr_writer :on_creature_use
      # Register the on_skill_choice block
      attr_writer :on_skill_choice
      # Register the on_skill_use block
      attr_writer :on_skill_use
      # Register the on_use block
      attr_writer :on_use
      # Register the action_to_push block
      attr_writer :action_to_push
      # Void all regular block for battle usage
      def void_non_battle_block
        @on_creature_use = nil
        @on_skill_use = nil
      end

      # Tell if the wrapper has a Pokemon choice
      # @return [Boolean]
      def on_creature_choice?
        !!@on_creature_choice
      end

      # Call the on_creature_choice block
      # @param creature [PFM::Pokemon]
      # @param scene [GamePlay::Base]
      # @return [Boolean]
      def on_creature_choice(creature, scene)
        return false unless @on_creature_choice.respond_to?(:call)
        return false if $game_temp.in_battle && creature.effects.has?(:embargo)

        return @on_creature_choice.call(@item, creature, scene)
      end

      # Call the on_creature_use block
      # @param creature [PFM::Pokemon]
      # @param scene [GamePlay::Base]
      def on_creature_use(creature, scene)
        @on_creature_use&.call(@item, creature, scene)
      end

      # Call the on_creature_choice block
      # @param skill [PFM::Skill]
      # @param scene [GamePlay::Base]
      # @return [Boolean]
      def on_skill_choice(skill, scene)
        return false unless @on_skill_choice.respond_to?(:call)

        return @on_skill_choice.call(@item, skill, scene)
      end

      # Call the on_skill_use block
      # @param creature [PFM::Pokemon]
      # @param skill [PFM::Skill]
      # @param scene [GamePlay::Base]
      def on_skill_use(creature, skill, scene)
        @on_skill_use&.call(@item, creature, skill, scene)
      end

      # Call the on_use block
      # @param scene [GamePlay::Base]
      def on_use(scene)
        @on_use&.call(@item, scene)
      end

      # Call the action_to_push block
      def execute_battle_action
        raise 'You forgot to bind this wrapper!' unless @scene

        if @skill
          @action_to_push&.call(@item, @creature, @skill, @scene)
        else
          @action_to_push&.call(@item, @creature, @scene)
        end
      end

      # Bind the wrapper to a scene, creature & skill
      # @param scene [GamePlay::Base]
      # @param creature [PFM::Pokemon]
      # @param skill [PFM::Skill]
      def bind(scene, creature, skill = nil)
        @scene = scene
        @creature = creature
        @skill = skill
      end
    end

    # Specific case sacred_ash
    define_chen_prevention(:sacred_ash) { $actors.none? { |creature| creature.dead? && !creature.egg? } }
    define_bag_use(:sacred_ash) do
      $actors.compact.each do |pkmn|
        next unless pkmn.hp <= 0

        pkmn.cure
        pkmn.hp = pkmn.max_hp
        pkmn.skills_set.compact.each { |j| j.pp = j.ppmax }
        $scene.display_message(parse_text(22, 115, PFM::Text::PKNICK[0] => pkmn.given_name))
      end
    end
    # Specific case honey
    define_chen_prevention(:honey) { !$env.normal? || $env.grass? || $env.building? }
    define_bag_use(:honey) do
      next $scene.display_message(text_get(39, 7).clone) unless $wild_battle.available?

      $scene.return_to_scene(::Scene_Map)
      $game_system.map_interpreter.launch_common_event(1)
    end

    # Specific case ability_capsule
    define_chen_prevention(:ability_capsule) { $game_temp.in_battle }
    define_on_creature_usability(:ability_capsule) do |item, creature|
      next false if creature.egg?
      next false if %i[zygarde greninja].include?(creature.db_symbol)
      next false if creature.db_symbol == :rockruff && creature.ability_db_symbol == :own_tempo
      next false if creature.data.abilities[0] == creature.data.abilities[1]
      next false if creature.ability_db_symbol == creature.data.abilities.last
    
      next true
    end

    define_on_creature_use(:ability_capsule) do |item, creature, scene|
      creature.ability_index = creature.ability_index.zero? ? 1 : 0
      creature.update_ability
      $scene.display_message_and_wait(parse_text_with_pokemon(19, 405, creature, PFM::Text::ABILITY[1] => creature.ability_name))
    end

    # All the event conditions
    define_event_condition(6)
    define_event_condition(7)
    define_event_condition(11) do
      next false if $game_player.surfing?

      next $game_switches[Yuki::Sw::EV_Bicycle] || $game_switches[Yuki::Sw::Env_CanFly] || $game_switches[Yuki::Sw::Env_CanDig]
    end
    define_event_condition(13) { $game_switches[Yuki::Sw::Env_CanDig] }
    define_event_condition(14) { $game_switches[Yuki::Sw::Env_CanDig] }
    define_event_condition(19)
    define_event_condition(22) { Game_Character::SurfTag.include?($game_player.front_system_tag) }
    define_event_condition(23) { Game_Character::SurfTag.include?($game_player.front_system_tag) }
    define_event_condition(24) { Game_Character::SurfTag.include?($game_player.front_system_tag) }
    define_event_condition(33) do
      next false if $game_player.surfing?

      next $game_switches[Yuki::Sw::EV_AccroBike] || $game_switches[Yuki::Sw::Env_CanFly] || $game_switches[Yuki::Sw::Env_CanDig]
    end
  end
end
