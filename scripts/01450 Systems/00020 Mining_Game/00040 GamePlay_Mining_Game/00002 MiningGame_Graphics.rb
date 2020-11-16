module GamePlay
  class MiningGame
    include UI::MiningGame

    private

    # Create the graphics
    def create_graphics
      super
      # Ensure the handler is ready before creating the graphics
      Graphics.update until @handler.ready?
      create_background
      create_tool_buttons
      create_diggable_stacks
      create_tiles_stack
      create_hit_counter
      create_tool_hit_sprite
      create_iron_hit_sprite
      create_tool_sprite
      create_transition
      update_transition
      launch_ping_text
    end

    # Create the transition (black screen)
    def create_transition
      @transition.dispose if @transition.is_a? Yuki::Sprite
      @transition = Yuki::Sprite.new(@viewport)
      @transition.set_bitmap('mining_game/black_background', :interface)
      if [:transition_in, :end_transition_in].include? @ui_state
        @transition.y -= @transition.height
      elsif [:transition_out, :end_transition_out].include? @ui_state
        @transition.y -= 0
      end
    end

    # Update the black screen transition
    def update_transition
      if [:transition_in, :end_transition_in].include? @ui_state
        limit = 0
      elsif [:transition_out, :end_transition_out].include? @ui_state
        limit = 0 - LiteRGSS::Config::ScreenHeight
      end
      @transition.move_to(0, limit, 30)
      until @transition.y == limit do 
        @transition.update_position
        Graphics.wait(1)
      end
      @ui_state = :mouse if @ui_state == :transition_out
      @ui_state = :transition_out if @ui_state == :transition_in
      @ui_state = :end_transition_out if @ui_state == :end_transition_in
    end

    # Update the graphics that needs to be updated (and @animation)
    def update_graphics
      @tool_buttons.animation.update if @tool_buttons.animation && !@tool_buttons.animation.done?
      return unless @ui_state == :animation
      return if !@animation || @animation.done?

      @animation.update
      @tool_sprite.update
      @tool_hit_sprite.update
      @ui_state = :mouse if @animation.done?
    end

    # Create the background
    def create_background
      @background = Background.new(@viewport)
    end

    # Create the tool buttons
    def create_tool_buttons
      @tool_buttons = Tool_Buttons.new(@viewport)
    end

    # Create the stack of diggables
    def create_diggable_stacks
      @diggable_stack = Diggable_Stack.new(@viewport, @handler.arr_items, @handler.arr_irons)
    end

    # Create the stack of tiles
    def create_tiles_stack
      @tiles_stack = Tiles_Stack.new(@viewport, @handler.arr_tiles_state)
    end

    # Create the hit counter
    def create_hit_counter
      @hit_counter_stack = Hit_Counter_Stack.new(@viewport)
    end

    # Create the tool's sprite
    def create_tool_sprite
      @tool_sprite = Tool_Sprite.new(@viewport)
    end

    # Create the tool's hit sprite
    def create_tool_hit_sprite
      @tool_hit_sprite = Tool_Hit_Sprite.new(@viewport)
    end

    # Create the iron's hit sprite
    def create_iron_hit_sprite
      @iron_hit_sprite = Sprite.new(@viewport)
      @iron_hit_sprite.set_bitmap('mining_game/iron_hit', :interface)
                      .visible = false
    end
  end
end
