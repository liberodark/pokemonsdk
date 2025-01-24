module BattleUI
  # Sprite of a Pokemon in the battle when BATTLE_CAMERA_3D is true
  # Sprite3D calculates Coordinates from the center of the Viewport
  class PokemonSprite3D < PokemonSprite
    # Standard duration of the animations
    ANIMATION_DURATION = 0.75

    # Create a new PokemonSprite
    # @param viewport [Viewport]
    # @param scene [Battle::Scene]
    # @param camera [Fake3D::Camera]
    # @param camera_positionner [Visual3D::CameraPositionner]
    def initialize(viewport, scene, camera, camera_positionner)
      super(viewport, scene)
      @camera = camera
      @camera_positionner = camera_positionner
    end

    # Update the sprite
    def update
      @animation_handler.update
      @gif&.update(bitmap) unless pokemon&.dead? || pokemon&.status == 5
      @animation_tone&.update unless @stop_status_tone
      @shiny_animation&.update
    end

    # Set the z position of the sprite
    # @param z [Numeric]
    def z=(z)
      super
      z = shader_z_position
      shader.set_float_uniform('z', z)
      shadow.shader.set_float_uniform('z', z)
    end

    # Return the basic z position of the battler
    def shader_z_position
      z = @pokemon.bank == 0 ? 0.75 : 1
      return z
    end

    # Return the shadow characteristic of the PokemonSprite3D
    def shadow
      return @shadow
    end

    # Reset the zoom of the sprite
    def reset_zoom
      self.zoom = sprite_zoom
      set_tone_status(@pokemon.status, true)
    end

    # Set the zoom of the sprite
    # @param zoom [Float]
    def zoom=(zoom)
      super
      @shadow.zoom = zoom * 0.75
    end

    # Creates the go_in animation (Exiting the ball)
    # @param start_battle [Boolean] animation for the start of the battle
    # @return [Yuki::Animation::TimedAnimation]
    def go_in_animation(start_battle = false)
      regular_go_in_animation(start_battle)
    end

    # Creates the go_out animation (Entering the ball if not KO, shading out if KO)
    # @return [Yuki::Animation::TimedAnimation]
    def go_out_animation
      return ko_go_out_animation if pokemon.dead?

      return regular_go_out_animation
    end

    # Display immediatly the Follower in the battle (only used in transition in 3D)
    def follower_go_in_animation
      self.reset_zoom
      set_tone_status(@pokemon.status, true)
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

    # Load the battler of the Pokemon
    # @param forced [Boolean] if we force the loading of the battler (useful with Substitute cases)
    def load_battler(forced = false)
      super
      self.shader = Shader.create(:fake_3d)
    end

    # Set the position of the battler before being sent with a ball
    # @return [Yuki::Animation::TimedAnimation]
    def set_position_go_in(start_battle = false)
      color = [255, 255, 255, 1]
      ya = Yuki::Animation
      animation = ya.send_command_to(self.shader, :set_float_uniform, 'color', color)
      animation.play_before(ya.send_command_to(self, :zoom=, 0))
      animation.play_before(ya.send_command_to(self, :opacity=, 255))
      animation.play_before(ya.send_command_to(self, :set_position, *sprite_position))
      animation.play_before(ya.send_command_to(self, :y=, self.y - fall_height(start_battle)))

      return animation
    end

    # Creates the regular go in animation (not follower)
    # @param start_battle [Boolean] animation for the start of the battle
    # @return [Yuki::Animation::TimedAnimation]
    def regular_go_in_animation(start_battle = false)
      ya = Yuki::Animation

      burst = burst_settings(start_battle)

      animation = ya.send_command_to(self, :visible=, true)
      animation.play_before(set_position_go_in(start_battle))
      poke_out = poke_out_animation(start_battle)
      ball_animation = enemy? ? enemy_ball_animation : actor_ball_animation(start_battle)
      animation.play_before(ball_animation)
      burst_animation = create_burst_animation(burst)
      anim_wait = ya.wait(1.2)
      anim_wait.parallel_play(burst_animation)
      anim_wait.parallel_play(poke_out)
      animation.play_before(anim_wait)
      animation.play_before(ya.send_command_to(self, :set_tone_status, @pokemon.status, true))
      animation.play_before(ya.send_command_to(self, :shiny_animation))

      return animation
    end

    # Creates the regular go out animation (not follower)
    # @return [Yuki::Animation::TimedAnimation]
    def regular_go_out_animation
      sprite = UI::ThrowingBallSprite3D.new(viewport, @pokemon)
      sprite.retrieve_position(@bank, @position, @scene)
      burst = UI::RetrieveBurst.new(viewport)
      burst.set_position(sprite.x, sprite.y)

      ya = Yuki::Animation
      animation = ya.wait(0.1)
      animation.play_before(ya.se_play(*back_ball_se))
      ball_animation = ya.scalar(0.2, sprite, :close_progression=, 0, 3)

      anim_wait = ya.wait(0.8)
      anim_wait.parallel_play(return_to_ball_animation)
      anim_wait.parallel_play(create_retrieve_animation(burst))
      animation.play_before(ball_animation)
      animation.play_before(anim_wait)
      animation.play_before(ya.send_command_to(sprite, :dispose))

      return animation
    end

    # Create the fall and the white animation after using a Pokeball
    # @return [Yuki::Animation::TimedAnimation]
    def poke_out_animation(start_battle = false)
      origin_y = self.y - fall_height(start_battle)
      camera_y = camera_y_before_check(start_battle)
      y_shake = camera_shake_effect
      ya = Yuki::Animation
      animation = ya.send_command_to(self.shadow, :visible=, true)
      animation.play_before(ya.scalar(0.25, self, :zoom=, 0, sprite_zoom * 1.4))
      animation.play_before(ya.scalar(0.15, self, :zoom=, sprite_zoom * 1.4, sprite_zoom))
      animation.play_before(ya.scalar(0.25, method(:update_shader_alpha), :call, 1, 0))
      animation.play_before(ya.scalar(0.25, self, :y=, origin_y, sprite_position[1]))
      animation.play_before(ya.scalar(0.1, @camera_positionner, :y, camera_y, camera_y + y_shake))
      animation.parallel_play(ya.send_command_to(self.shadow, :visible=, true))
      animation.parallel_play(ya.send_command_to(self, :cry))
      animation.play_before(ya.scalar(0.1, @camera_positionner, :y, camera_y + y_shake, camera_y))

      return animation
    end

    # White animation when a Pokemon go back into its ball
    # @return [Yuki::Animation::TimedAnimation]
    def return_to_ball_animation
      ya = Yuki::Animation
      animation = ya.scalar(0.2, method(:update_shader_alpha), :call, 0, 1)
      animation.parallel_play(ya.scalar(0.75, self, :zoom=, sprite_zoom, 0))

      return animation
    end

    # Update the shader's alpha uniform
    # @param alpha [Float] the alpha value (0 to 1)
    def update_shader_alpha(alpha)
      color = [255, 255, 255, alpha]
      self.shader.set_float_uniform('color', color)
    end

    # Create the ball animation of the enemy Pokemon
    # @return [Yuki::Animation::TimedAnimation]
    def enemy_ball_animation
      sprite = UI::ThrowingBallSprite3D.new(viewport, @pokemon)
      sprite.reset_position(@bank, @position, @scene)
      sprite.opacity = 0
      sprite.zoom = 0.5
      ya = Yuki::Animation
      animation = ya.scalar(0.5, sprite, :opacity=, 0, 255)
      animation.parallel_play(ya.scalar(0.5, sprite, :throw_progression=, 0, 1))
      animation.parallel_play(ya.se_play(*sending_ball_se))
      animation.play_before(ya.se_play(*opening_ball_se))
      animation.play_before(ya.send_command_to(sprite, :dispose))

      return animation
    end

    # Create the ball animation of the actor Pokemon
    # @param start_battle [Boolean] animation for the start of the battle
    # @param pokemon_going_out_of_ball_animation [Yuki::Animation::TimedAnimation]
    def actor_ball_animation(start_battle = false)
      sprite = UI::ThrowingBallSprite3D.new(viewport, @pokemon)
      sprite.reset_position(@bank, @position, @scene, start_battle)
      x_reach = x + sprite.actor_ball_offset(@position, @scene, start_battle)[0]
      y_reach = y + sprite.actor_ball_offset(@position, @scene, start_battle)[1]
      sprite.opacity = 0
      sprite.zoom = 0.9
      ya = Yuki::Animation
      animation = ya.scalar_offset(0.8, sprite, :y, :y=, 0, -32, distortion: :SQUARE010_DISTORTION)
      animation.parallel_play(ya.send_command_to(sprite, :opacity=, 255))
      animation.parallel_play(ya.move(0.8, sprite, sprite.x, sprite.y, x_reach, y_reach))
      animation.parallel_play(ya.scalar(0.8, sprite, :throw_progression=, 0, 3))
      animation.parallel_play(ya.scalar(0.8, sprite, :zoom=, 0.9, 0.7))
      animation.parallel_play(ya.se_play(*sending_ball_se))
      animation.play_before(ya.scalar(0.5, sprite, :throw_progression=, 0, 2))
      animation.play_before(ya.se_play(*opening_ball_se))
      animation.play_before(ya.send_command_to(sprite, :dispose))

      return animation
    end

    def burst_settings(start_battle = false)
      burst = UI::BallBurst.new(viewport, @pokemon)
      burst.opacity = 0
      burst.reset_position(@bank, @position, @scene, start_battle)

      return burst
    end

    def create_burst_animation(burst)
      ya = Yuki::Animation

      burst_animation = ya.send_command_to(burst, :opacity=, 255)
      burst_animation.play_before(ya.scalar(0.65, burst, :open_progression=, 0, 1))
      burst_animation.play_before(ya.send_command_to(burst, :dispose))

      return burst_animation
    end

    def create_retrieve_animation(burst)
      ya = Yuki::Animation

      burst_animation = ya.scalar(0.65, burst, :retrieve_progression=, 0, 1)
      burst_animation.play_before(ya.send_command_to(burst, :dispose))

      return burst_animation
    end

    # Get the base position of the Pokemon in 1v1
    # @return [Array<Integer, Integer>]
    def base_position_v1
      return 82, 18 if enemy?

      return -34, 64
    end

    # Get the base position of the Pokemon in 2v2+
    # @return [Array<Integer, Integer>]
    def base_position_v2
      return 42, 13 if enemy?

      return -78, 79
    end

    # Coordinates for the burst effect when the ball is opened
    # @param start_battle [Boolean] coordinates offset for the start of the battle
    def burst_offset(start_battle = false)
      return 8, 0 if enemy?

      return start_battle ? [96, 6] : [136, -45]
    end

    def camera_y_before_check(start_battle = false)
      return 0 if enemy?

      return start_battle ? 20 : 0
    end

    # Intensity of the skake effect when the Pokemon hits the ground
    # @return [Integer]
    def camera_shake_effect
      return 5 # Could make it change depending of the weight
    end

    # Height fo the fall of a Pokémon Sprite
    # @return [Integer]
    def fall_height(start_battle = false)
      return start_battle ? 60 : 95
    end

    # Pokemon sprite zoom
    # @return [Integer]
    def sprite_zoom
      return enemy? ? 1 : 1.34
    end
  end
end