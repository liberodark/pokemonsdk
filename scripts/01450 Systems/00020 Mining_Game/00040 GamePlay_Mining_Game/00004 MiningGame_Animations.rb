module GamePlay
  class MiningGame
    private

    # Play all the animations resulting from a hit
    # @param x [Integer] the x coordinate of the tile
    # @param y [Integer] the y coordinate of the tile
    # @param diggable [PFM::MiningGame::Diggable, Boolean] either the actual object or a boolean (true for iron, false otherwise)
    # @param reveal [Boolean] true if the Diggable is revealed or already revealed otherwise false
    # @param newly_revealed [Boolean] if the item is fully revealed for the first time
    def play_hit_animation(x, y, diggable, reveal, newly_revealed)
      @ui_state = :animation
      @tool_sprite.change_tool(@current_tool)
      @tool_hit_sprite.change_tool(@current_tool)
      @tool_sprite.set_position(x * 16 + 14, y * 16 + 32 - 20)
      @tool_sprite.visible = true
      @tool_hit_sprite.set_position(x * 16 - 17, y * 16 + 32 - 17)
      @iron_hit_sprite.set_position(x * 16 - 17, y * 16 + 32 - 17)
      anim = Yuki::Animation
      @animation = anim.wait(0.01)
      @animation.play_before(anim.wait(0.01))
                .parallel_add(tool_sprite_anim(diggable, reveal, newly_revealed))
                .parallel_add(tool_hit_sprite_anim(diggable, reveal))
                .parallel_add(sound_anim(diggable, reveal, newly_revealed))
      @animation.start
    end

    # Setup the animation for @tool_sprite
    # @param diggable [PFM::MiningGame::Diggable, Boolean] either the actual object or a boolean (true for iron, false otherwise)
    # @param reveal [Boolean] if an item is revealed by the hit
    # @param newly_revealed [Boolean] if an item is fully revealed for the first time
    # @return animation [Yuki::Animation::ResolverObjectCommand]
    def tool_sprite_anim(diggable, reveal, newly_revealed)
      anim = Yuki::Animation
      animation = anim.send_command_to(@tool_sprite, :sx=, 0)
      animation.play_before(anim.wait(0.03))
      # .parallel_add are added in parallel of the play_before parameter
      if @current_tool != :dynamite
        animation.play_before(anim.wait(0.01))
                 .parallel_add(anim.send_command_to(@tool_sprite, :sub_to_x, 8))
                 .parallel_add(anim.send_command_to(@tool_sprite, :add_to_y, 8))
        animation.play_before(anim.wait(0.12))
        animation.play_before(anim.wait(0.01))
                 .parallel_add(anim.send_command_to(@tool_sprite, :new_frame))
                 .parallel_add(anim.send_command_to(@tool_sprite, :add_to_x, 8))
                 .parallel_add(anim.send_command_to(@tool_sprite, :sub_to_y, 8))
        animation.play_before(anim.wait(0.06))
        animation.play_before(anim.wait(0.01))
                 .parallel_add(anim.send_command_to(@tool_sprite, :add_to_x, 3))
        animation.play_before(anim.wait(0.10))
        animation.play_before(anim.send_command_to(@tool_sprite, :sub_to_x, 3))
        animation.play_before(anim.wait(0.10))
      else
        animation.play_before(anim.wait(0.06))
        animation.play_before(anim.wait(0.01))
                 .parallel_add(anim.send_command_to(@tool_sprite, :sub_to_x, 15))
                 .parallel_add(anim.send_command_to(@tool_sprite, :add_to_y, 15))
                 .parallel_add(anim.send_command_to(@tool_sprite, :new_frame))
        animation.play_before(anim.wait(0.06))
        animation.play_before(anim.wait(0.01))
        animation.play_before(anim.send_command_to(@tool_sprite, :sub_to_x, 3))
        animation.play_before(anim.wait(0.10))
        animation.play_before(anim.wait(0.01))
                 .parallel_add(anim.send_command_to(@tool_sprite, :add_to_x, 6))
        animation.play_before(anim.wait(0.10))
        animation.play_before(anim.send_command_to(@tool_sprite, :sub_to_x, 3))
        animation.play_before(anim.wait(0.10))
      end
      animation.play_before(anim.send_command_to(@tool_sprite, :visible=, false))
      return animation
    end

    # Setup the animation for @tool_hit_sprite or @iron_hit_sprite
    # @param diggable [PFM::MiningGame::Diggable, Boolean] either the actual object or a boolean (true for iron, false otherwise)
    # @param reveal [Boolean] if an item is revealed by the hit
    # @return animation [Yuki::Animation::ResolverObjectCommand]
    def tool_hit_sprite_anim(diggable, reveal)
      anim = Yuki::Animation
      nb = diggable ? 1 : 0
      sprite = (diggable == true && reveal) ? @iron_hit_sprite : @tool_hit_sprite
      animation = anim.send_command_to(sprite, :visible=, true)
      animation.play_before(anim.send_command_to(@tool_hit_sprite, :sx=, nb)) unless diggable == true
      animation.play_before(anim.wait(0.03))
      animation.play_before(anim.send_command_to(sprite, :visible=, false)) if !diggable.is_a? PFM::MiningGame::Diggable
      animation.play_before(anim.send_command_to(@tool_hit_sprite, :new_frame)) if diggable.is_a? PFM::MiningGame::Diggable
      animation.play_before(anim.wait(0.06))
      animation.play_before(anim.send_command_to(sprite, :visible=, true)) if !diggable.is_a? PFM::MiningGame::Diggable
      animation.play_before(anim.send_command_to(@tool_hit_sprite, :new_frame)) if diggable.is_a? PFM::MiningGame::Diggable
      animation.play_before(anim.wait(0.02))
      animation.play_before(anim.send_command_to(@tool_hit_sprite, :new_frame)) if diggable.is_a? PFM::MiningGame::Diggable
      animation.play_before(anim.wait(0.04))
      animation.play_before(anim.send_command_to(sprite, :visible=, false))
      animation.play_before(anim.wait(0.03))
      animation.play_before(anim.send_command_to(sprite, :visible=, true))
      animation.play_before(anim.wait(0.03))
      animation.play_before(anim.send_command_to(sprite, :visible=, false))
      return animation
    end

    # Setup the Audio part of the animation
    # @param diggable [PFM::MiningGame::Diggable, Boolean] either the actual object or a boolean (true for iron, false otherwise)
    # @param reveal [Boolean] if an item is revealed by the hit
    # @param newly_revealed [Boolean] if an item is fully revealed for the first time
    # @return animation [Yuki::Animation::TimedAnimation]
    def sound_anim(diggable, reveal, newly_revealed)
      anim = Yuki::Animation
      animation = anim.wait(0)
      animation.play_before(anim.se_play("mining_game/#{@current_tool}")) if diggable != true || reveal == false
      animation.play_before(anim.se_play('mining_game/iron')) if diggable == true && reveal
      animation.play_before(anim.wait(0.10))
      animation.play_before(anim.se_play('mining_game/reveal')) if (diggable.is_a? PFM::MiningGame::Diggable) && reveal
      animation.play_before(anim.wait(0.07))
      animation.play_before(anim.se_play('mining_game/fully_reveal')) if newly_revealed
      return animation
    end

    # Play the wall collapsing animation
    def wall_collapse_anim
      @sprite = Sprite.new(@viewport)
      @sprite.set_bitmap('mining_game/black_screen', :interface)
      @sprite.set_rect(0, 0, 320, 0)
      until @sprite.src_rect.height == 240
        @sprite.src_rect.height += 8
        Graphics.wait(1)
      end
    end
  end
end
