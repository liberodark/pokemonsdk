module BattleUI
  # Sprite of a Pokemon in the battle when BATTLE_CAMERA_3D is true
  # Sprite3D calculates Coordinates from the center of the Viewport
  class PokemonSprite3D < PokemonSprite
    # Set the z position of the sprite
    # @param z [Numeric]
    def z=(z)
      super
      z = shader_z_position
      shader.set_float_uniform('z', z)
      shadow.shader.set_float_uniform('z', z)
    end

    # Return the shadow characteristic of the PokemonSprite3D
    def shadow
      return @shadow
    end

    private

    # create the shadow of the Pokemon with a shader
    def create_shadow
      @shadow = ShaderedSprite.new(viewport)
      @shadow.shader = Shader.create(:battle_shadow_3d)
    end

    # Reset the battler position
    def reset_position
      set_position(*sprite_position)
      self.z = basic_z_position
      set_origin(width / 2, height)
    end

    # Return the basic z position of the battler
    def shader_z_position
      z = @pokemon.bank == 0 ? 0.5 : 1
      return z
    end

    # Load the battler of the Pokemon
    # @param forced [Boolean] if we force the loading of the battler (useful with Substitute cases)
    def load_battler(forced = false)
      super
      self.shader = Shader.create(:fake_3d)
    end

    # Creates the regular go in animation (not follower)
    # @return [Yuki::Animation::TimedAnimation]
    def regular_go_in_animation
      ya = Yuki::Animation
      animation = ya.send_command_to(self, :visible=, true)
      animation.play_before(ya.send_command_to(self, :zoom=, 0))
      animation.play_before(ya.send_command_to(self, :opacity=, 255))
      animation.play_before(ya.send_command_to(self, :set_position, *sprite_position))
      poke_out = ya.scalar(0.1, self, :zoom=, 0, sprite_zoom)
      ball_animation = enemy? ? enemy_ball_animation(poke_out) : actor_ball_animation(poke_out)
      animation.play_before(ball_animation)
      animation.play_before(ya.send_command_to(self, :cry))

      return animation
    end

    # Create the ball animation of the enemy Pokemon
    # @param pokemon_going_out_of_ball_animation [Yuki::Animation::TimedAnimation]
    # @return [Yuki::Animation::TimedAnimation]
    def enemy_ball_animation(pokemon_going_out_of_ball_animation)
      sprite = UI::ThrowingBallSprite.new(viewport, @pokemon)
      sprite.set_position(*sprite_position)
      sprite.y += Graphics.height / 2 - sprite.ball_offset_y * 2
      sprite.x += Graphics.width / 2 + sprite.ball_offset_y
      ya = Yuki::Animation
      animation = ya.wait(0.2)
      animation.play_before(ya.se_play(*opening_ball_se))
      animation.play_before(ya.scalar(0.1, sprite, :open_progression=, 0, 1))
      animation.play_before(ya.send_command_to(sprite, :dispose))
      animation.play_before(pokemon_going_out_of_ball_animation)

      return animation
    end

    # Create the ball animation of the actor Pokemon
    # @param pokemon_going_out_of_ball_animation [Yuki::Animation::TimedAnimation]
    # @return [Yuki::Animation::TimedAnimation]
    def actor_ball_animation(pokemon_going_out_of_ball_animation)
      sprite = UI::ThrowingBallSprite.new(viewport, @pokemon)
      sprite.set_position(-sprite.ball_offset_y, y - sprite.trainer_offset_y)
      ya = Yuki::Animation
      animation = ya.scalar_offset(0.5, sprite, :y, :y=, 0, -64, distortion: :SQUARE010_DISTORTION)
      animation.parallel_play(ya.move(0.5, sprite, -sprite.ball_offset_y, y - sprite.trainer_offset_y, x + Graphics.width/2, y - sprite.ball_offset_y + Graphics.height/2))
      animation.parallel_play(ya.scalar(0.5, sprite, :throw_progression=, 0, 1))
      animation.parallel_play(ya.se_play(*sending_ball_se))
      animation.play_before(ya.se_play(*opening_ball_se))
      animation.play_before(ya.scalar(0.1, sprite, :open_progression=, 0, 1))
      animation.play_before(ya.send_command_to(sprite, :dispose))
      animation.play_before(pokemon_going_out_of_ball_animation)

      return animation
    end

    # Create the ball animation of the Pokemon going back in ball
    # @param pokemon_going_in_the_ball_animation [Yuki::Animation::TimedAnimation]
    # @return [Yuki::Animation::TimedAnimation]
    def go_back_ball_animation(pokemon_going_in_the_ball_animation)
      sprite = UI::ThrowingBallSprite.new(viewport, @pokemon)
      sprite.set_position(*sprite_position)
      sprite.y += Graphics.height/2
      sprite.x += Graphics.width/2
      ya = Yuki::Animation
      animation = ya.wait(0.2)
      animation.play_before(ya.se_play(*back_ball_se))
      animation.play_before(ya.scalar(0.1, sprite, :open_progression=, 0, 1))
      animation.play_before(ya.send_command_to(sprite, :dispose))
      animation.play_before(pokemon_going_in_the_ball_animation)

      return animation
    end

    # Creates the go_out animation of a "follower" pokemon
    # @return [Yuki::Animation::TimedAnimation]
    def follower_go_out_animation
      x, y = sprite_position
      bx = enemy? ? viewport.rect.width + width + Battleback3D::MARGIN_X : -(width+Battleback3D::MARGIN_X)
      return Yuki::Animation.move(0.2, self, x, y, bx, y)
    end

    # Get the base position of the Pokemon in 1v1
    # @return [Array(Integer, Integer)]
    def base_position_v1
      return 82, 18 if enemy?

      return -34, 64
    end

    # Get the base position of the Pokemon in 2v2+
    # @return [Array(Integer, Integer)]
    def base_position_v2
      return 42, 13 if enemy?

      return -78, 59
    end
  end
end