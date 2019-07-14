module GamePlay
  # Move reminder Scene
  class Move_Reminder < Base
    BACKGROUND = 'MR_UI'
    CURSOR = 'ball_selec'
    # @return [Boolean] if the pokemon learnt a move
    attr_reader :return_data
    # Create a new Move_Reminder Scene
    # @param pokemon [PFM::Pokemon] pokemon that should learn a move
    # @param mode [Integer] Define the moves you can see :
    #   1 = breed_moves + learnt + potentially_learnt
    #   2 = all moves
    #   other = learnt + potentially_learnt
    def initialize(pokemon, mode = 0)
      super
      @index = 0
      @pokemon = pokemon
      @move_set = pokemon.remindable_skills(mode)
      @viewport = Viewport.create(:main, 1000)
      @stack = UI::SpriteStack.new(@viewport)
      @summary = []
      create_background
      create_cursor
      create_move_texts
      create_summary_texts
      refresh_summary
    end

    # Update the scene
    def update
      if index_changed(:@index, :UP, :DOWN, @move_set.size - 1)
        refresh_summary
        refresh_skills
        update_cursor
      elsif Input.trigger?(:A)
        action_a
      elsif Input.trigger?(:B)
        $game_system.se_play($data_system.cancel_se)
        @return_data = false
        @running = false
      end
    end

    private

    # Call the Skill Learn UI when the player press A
    def action_a
      $game_system.se_play($data_system.decision_se)
      scene = GamePlay::Skill_Learn.new(@pokemon, @move_set[@index])
      scene.main
      if scene.learnt
        @return_data = true
        @running = false
      else
        Graphics.transition
      end
    end

    # Create the background
    def create_background
      @stack.push(0, 13, BACKGROUND)
    end

    # Create the cursor
    def create_cursor
      @cursor = Sprite.new(@viewport)
      @cursor.set_bitmap(CURSOR, :interface).set_position(9, 60)
    end

    # Create the move texts
    def create_move_texts
      @texts = []
      @move_set.each_with_index do |move, i|
        break if i == 10 || !move
        name = GameData::Skill.name(move)
        @texts << @stack.add_text(15 + @cursor.width, 54 + 16 * i, 0, 15, name)
      end
    end

    # Create the summary texts
    def create_summary_texts
      @summmary_descr = @stack.add_text(120, 100, 198, 18, nil.to_s)
      @summary_pp = @stack.add_text(120, 6, 0, 68, nil.to_s)
      @summary_power = @stack.add_text(120, 23, 0, 68, nil.to_s)
      @summary_acc = @stack.add_text(120, 40, 0, 68, nil.to_s)
      @summary_cat_text = @stack.add_text(120, 57, 0, 68, category_text)
      @summary_cat_image = @stack.add_sprite(273, 80, nil)
    end

    # Return the category text
    # @return [String]
    def category_text
      "#{text_get(27, 36)} :"
    end

    # Return the PP text
    # @return [String]
    def pp_text
      "PP : #{GameData::Skill.pp_max(@move_set[@index])}"
    end

    # Return the power text
    # @return [String]
    def power_text
      power = GameData::Skill.power(@move_set[@index])
      power = '---' if power == 0
      "#{text_get(27, 37)} : #{power}"
    end

    # Return the accuracy text
    # @return [String]
    def accuracy_text
      accuracy = GameData::Skill.accuracy(@move_set[@index])
      accuracy = '---' if accuracy == 0
      "#{text_get(27, 39)} : #{accuracy}"
    end

    # Refresh the summary texts
    def refresh_summary
      @summmary_descr.multiline_text = GameData::Text.get(7, @move_set[@index])
      @summary_pp.text = pp_text
      @summary_power.text = power_text
      @summary_acc.text = accuracy_text
      @summary_cat_image.set_bitmap("c#{GameData::Skill.atk_class(@move_set[@index])}", :interface)
    end

    # Refresh the skill list
    def refresh_skills
      if @index >= 9
        i = 9
        @texts.each do |text|
          text.text = GameData::Skill.name(@move_set[@index - i])
          i -= 1
        end
      elsif @index == 0
        @texts.each_with_index do |text, index|
          text.text = GameData::Skill.name(@move_set[index])
        end
      end
    end

    # Update the cursor position
    def update_cursor
      if @index < 9
        @cursor.set_position(9, 60 + 16 * @index)
      else
        @cursor.set_position(9, 60 + 16 * 9)
      end
    end
  end
end
