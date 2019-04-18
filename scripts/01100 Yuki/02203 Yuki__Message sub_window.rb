module Yuki
  class Message
    private

    # Generate the choice window
    def generate_choice_window
      if $game_temp.choice_max > 0
        @choice_window = ChoiceWindow.generate_for_message(self)
      elsif $game_temp.num_input_digits_max > 0
        @input_number_window = ::GamePlay::InputNumber.new($game_temp.num_input_digits_max)
        if $game_system.message_position != 0
          @input_number_window.y = y - @input_number_window.height - 2
        else
          @input_number_window.y = y + height + 2
        end
        @input_number_window.z = z + 1
        @input_number_window.update
      end
      @drawing_message = false
    end

    # Show a window that tells the player how much money he got
    def show_gold_window
      return if @gold_window
      @gold_window = Window.new(viewport)
      @gold_window.lock
      wb = @gold_window.window_builder = window_builder
      @gold_window.windowskin = windowskin
      @gold_window.set_size(48 + windowskin.width - wb[2], 32 + wb[1])
      @gold_window.set_position(318 - @gold_window.width, 2)
      @gold_window.z = z + 1
      @gold_window.unlock
      stack = UI::SpriteStack.new(@gold_window)
      stack.add_text(0, 0, 44, 16, ::GameData::Text.get(11, 6))
      stack.add_text(0, 16, 44, 16, ::PFM::Text.parse(11, 9, ::PFM::Text::NUM7R => $pokemon_party.money.to_s), 2)
      nil
    end
  end
end
