module Yuki
  class Message
    private

    # Generate the choice window
    def generate_choice_window
      if($game_temp.choice_max > 0)
        @choice_window = ChoiceWindow.generate_for_message(self)
      elsif $game_temp.num_input_digits_max > 0
        @input_number_window = ::GamePlay::InputNumber.new($game_temp.num_input_digits_max)
        if($game_system.message_position != 0)
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
      @gold_window = ::Game_Window.new(viewport)
      wb = @gold_window.window_builder = window_builder
      @gold_window.y = 2
      @gold_window.z = z + 1
      @gold_window.width = 96 + windowskin.width - wb[2]
      @gold_window.height = 32 + windowskin.height - wb[3]
      @gold_window.x = 318 - @gold_window.width
      @gold_window.windowskin = windowskin
      @gold_window.add_text(0, 0, 96, 16, ::GameData::Text.get(11, 6))
      @gold_window.add_text(0, 16, 96, 16, ::PFM::Text.parse(11, 9, ::PFM::Text::NUM7R => $pokemon_party.money.to_s), 2)
    end
  end
end