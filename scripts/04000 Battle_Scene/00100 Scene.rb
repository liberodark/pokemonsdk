# Module that holds all the Battle related classes
module Battle
  # Base classe of all the battle scene
  class Scene < GamePlay::Base
    # @return [Battle::Visual]
    attr_reader :visual
    # @return [Battle::Logic]
    attr_reader :logic

    # Create a new Battle Scene
    # @note This method create the banks, the AI, the pokemon battlers and the battle logic
    #       It should call the logic_init event
    # TODO : Input parameter to setup the battle (tell how much IA should be instancied the teams etc...)
    def initialize
      # Call the initialize of GamePlay::Base (show message box at z index 10001)
      super(false, 10_001)

      @logic = create_logic
      @visual = create_visual
      @AIs = Array.new(1) { create_ai }
      # Next method called in update
      @next_update = :pre_transition
      # List of the player actions
      @player_actions = []
      # Battle result
      @battle_result = :draw
      # All the event procs
      @battle_events = {}
      call_event(:logic_init)
    end

    # Update the scene
    def update
      # Update the visuals
      @visual.update
      # Prevent update if a message is showing
      return unless super
      # Call the next method
      send(@next_update)
    end

    # Dispose the battle scene
    def dispose
      super
      @visual.dispose
    end

    private

    # Create a new logic object
    # @return [Battle::Logic]
    def create_logic
      return Battle::Logic.new(self)
    end

    # Create a new visual
    # @return [Battle::Visual]
    def create_visual
      return Battle::Visual.new(self)
    end

    # Create a new AI
    # @return [Battle::AI]
    def create_ai
      return Battle::AI.new(self)
    end

    # Method that call @visual.show_pre_transition and change @next_update to :transition_animation
    def pre_transition
      @visual.show_pre_transition
      @next_update = :transition_animation
    end

    # Method that call @visual.show_transition and change @next_update to :player_action_choice
    # @note It should call the battle_begin event
    def transition_animation
      @visual.show_transition
      @next_update = :player_action_choice
      call_event(:battle_begin)
    end
  end
end
