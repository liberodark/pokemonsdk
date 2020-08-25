module GamePlay
  class Skill_Learn
    # Update inputs every frame
    def update_inputs
      return false unless @state == :move_choice
      return update_buttons_inputs
    end

    private

    # Update buttons inputs
    def update_buttons_inputs
      old_index = @index
      if Input.trigger?(:UP)
        return false if @index == 4
        play_cursor_se
        if @index > 1 && @index < 4
          @index -= 2
        elsif @index < 2
          @index = 4
        end
      elsif Input.trigger?(:DOWN)
        return false if @index > 1 && @index < 4
        play_cursor_se
        if @index < 2 || @index > 3
          @index == 4 ? @index = 0 : @index += 2
        end
      elsif Input.trigger?(:LEFT)
        return false if @index == 0 || @index == 4
        play_cursor_se
        @index -= 1
      elsif Input.trigger?(:RIGHT)
        return false if @index == 3 || @index == 4
        play_cursor_se
        @index += 1
      elsif Input.trigger?(:A)
        if (@index < 4)
          play_decision_se
          @skill_set[@index].forget = true
          forget
        else
          message_end
        end
      elsif Input.trigger?(:B)
        play_cancel_se
        message_end
      else
        return true
      end
      swap_buttons(old_index)
      return false
    end

    def swap_buttons(old_index)
      @skill_set[old_index].selected = false
      @skill_set[@index].selected = true
      @skill_description.data = @index < 4 ? @pokemon.skills_set[@index] : @skill_learn
    end
  end
end