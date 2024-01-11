module Battle
  class Visual
    # Method that show the pre_transition of the battle
    def show_pre_transition
      # return if debug? && ARGV.includes?('skip_battle_transition')
      # @type [Battle::Visual::RBJ_WildTransition]
      @transition = battle_transition.new(@scene, @screenshot)
      @animations << @transition
      @transition.pre_transition
      @locking = true
    end

    # Method that show the trainer transition of the battle
    def show_transition
      # return show_debug_transition if debug? && ARGV.includes?('skip_battle_transition')
      # Load transtion (x/y, dpp, frlg)
      # store the transition loop
      # Show the message "issuing a battle"
      # store the enemy ball animation
      # Show the message "send x & y"
      # store the actor ball animation
      # show the message "send x & y"
      @animations << @transition
      @transition.transition
      @locking = true
    end

    # Function storing a battler sprite in the battler Hash
    # @param bank [Integer] bank where the battler should be
    # @param position [Integer, Symbol] Position of the battler
    # @param sprite [Sprite] battler sprite to set
    def store_battler_sprite(bank, position, sprite)
      @battlers[bank] ||= {}
      @battlers[bank][position] = sprite
    end

    # Retrieve the sprite of a battler
    # @param bank [Integer] bank where the battler should be
    # @param position [Integer, Symbol] Position of the battler
    # @return [BattleUI::PokemonSprite, nil] the Sprite of the battler if it has been stored
    def battler_sprite(bank, position)
      @battlers.dig(bank, position)
    end

    class << self
      # Register the transition resource type for a specific transition
      # @note If no resource type was registered, will send the default sprite one
      # @param id [Integer] id of the transition
      # @param resource_type [Symbol] the symbol of the resource_type (:sprite, :artwork_full, :artwork_small)
      def register_transition_resource(id, resource_type)
        return unless id.is_a?(Integer)
        return unless resource_type.is_a?(Symbol)

        TRANSITION_RESOURCE_TYPE[id] = resource_type
      end

      # Return the transition resource type for a given transition ID
      # @param id [Integer] ID of the transition
      # @return [Symbol]
      def transition_resource_type_for(id)
        resource_type = TRANSITION_RESOURCE_TYPE[id]
        return :sprite unless resource_type

        return resource_type
      end
    end

    private

    # Return the current battle transition
    # @return [Class]
    def battle_transition
      collection = $game_temp.trainer_battle ? TRAINER_TRANSITIONS : WILD_TRANSITIONS
      transition_class = collection[$game_variables[Yuki::Var::TrainerTransitionType]]
      log_debug("Choosen transition class : #{transition_class}")
      return transition_class
    end

    # Show the debug transition
    def show_debug_transition
      2.times do |bank|
        @scene.battle_info.battlers[bank].each_with_index do |battler, position|
          battler_sprite(bank, -position - 1)&.visible = false
        end
      end
      Graphics.transition(1)
    end

    # List of Wild Transitions
    # @return [Hash{ Integer => Class<Transition::Base> }]
    WILD_TRANSITIONS = {}

    # List of Trainer Transitions
    # @return [Hash{ Integer => Class<Transition::Base> }]
    TRAINER_TRANSITIONS = {}

    # List of the resource type for each transition
    # @return [Hash{ Integer => Symbol }]
    TRANSITION_RESOURCE_TYPE = []
  end
end
