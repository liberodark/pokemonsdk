module GamePlay
  class MiningGame
    # List of method called by automatic_input_update when pressing on a key
    AIU_KEY2METHOD = {
      A: :action_a, X: :action_x, LEFT: :action_left, RIGHT: :action_right, UP: :action_up, DOWN: :action_down
    }

    # Check if a keyboard key is pressed, else check for the win/lose condition
    # @return [Boolean] false if @running == false
    def update_inputs
      return save_instance_for_debug if Input::Keyboard.press?(Input::Keyboard::LControl) && debug? && !@saved_grid_debug
      return false if @transition_animation && !@transition_animation.done?
      return false if @running == false
      return false unless @ui_state == :playing

      check_win_lose_condition
      return false unless automatic_input_update(AIU_KEY2METHOD)

      return true
    end

    private

    # Monkey-patch of the original BaseCleanUpdate to catch the result of the automatic input check
    # @param key2method [Hash] Hash associating Input Keys to action method name
    # @return [Boolean] if the update_inputs should continue
    def automatic_input_update(key2method = AIU_KEY2METHOD)
      result = super
      change_controller_state(:keyboard) unless result
      return result
    end

    # Define the action realized when pressing the A button
    def action_a
      tile_click(*@last_tile_hit)
    end

    # Define the action realized when pressing the X button
    def action_x
      @current_tool = @tool_buttons.cycle_through_buttons
    end

    # Define the action realized when pressing the LEFT button
    def action_left
      x = (@last_tile_hit[0] - 1).clamp(0, NB_X_TILES - 1)
      @last_tile_hit[0] = x
      @keyboard_cursor.change_coordinates(@last_tile_hit)
    end

    # Define the action realized when pressing the RIGHT button
    def action_right
      x = (@last_tile_hit[0] + 1).clamp(0, NB_X_TILES - 1)
      @last_tile_hit[0] = x
      @keyboard_cursor.change_coordinates(@last_tile_hit)
    end

    # Define the action realized when pressing the UP button
    def action_up
      y = (@last_tile_hit[1] - 1).clamp(0, NB_Y_TILES - 1)
      @last_tile_hit[1] = y
      @keyboard_cursor.change_coordinates(@last_tile_hit)
    end

    # Define the action realized when pressing the DOWN button
    def action_down
      y = (@last_tile_hit[1] + 1).clamp(0, NB_Y_TILES - 1)
      @last_tile_hit[1] = y
      @keyboard_cursor.change_coordinates(@last_tile_hit)
    end

    # Change which controller is currently used (only useful to change the visibility of the cursor)
    # Currently, the @controller variable isn't used, but it's there just in case
    # @param reason [Symbol] :mouse or :keyboard depending on which sent a button trigger
    def change_controller_state(reason)
      @controller = reason
      @keyboard_cursor.visible = (reason == :keyboard)
    end
  end
end
