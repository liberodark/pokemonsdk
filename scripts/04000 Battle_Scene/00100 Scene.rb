# Module that holds all the Battle related classes
module Battle
  # Base classe of all the battle scene
  class Scene < GamePlay::Base
    # @return [Battle::Visual]
    attr_reader :visual
    # @return [Battle::Logic]
    attr_reader :logic
    # @return [Battle::Logic::BattleInfo]
    attr_reader :battle_info

    # Create a new Battle Scene
    # @param battle_info [Battle::Logic::BattleInfo] informations about the battle
    # @note This method create the banks, the AI, the pokemon battlers and the battle logic
    #       It should call the logic_init event
    def initialize(battle_info)
      # Call the initialize of GamePlay::Base (show message box at z index 10001)
      super(false, 10_001)
      @battle_info = battle_info
      $game_temp.vs_type = battle_info.vs_type
      $game_temp.trainer_battle = battle_info.trainer_battle?
      @logic = create_logic
      @visual = create_visual
      @AIs = Array.new(count_ai_battler) { create_ai }
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

    # Disable the Graphics.transition
    def main_begin() end

    # Update the scene
    def update
      # Update the visuals
      @visual.update
      # Prevent update if a message is showing
      return unless super && !@visual.locking?
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

    # Function counting the number of AI required
    # @return [Integer]
    def count_ai_battler
      count = -1
      @battle_info.parties.each do |bank|
        count += bank.size
      end
      return count
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

    # Return the message class used by this scene
    # @return [Class]
    def message_class
      return Scene_Battle::Message
    end
  end
end
