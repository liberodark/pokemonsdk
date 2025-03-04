module BattleUI
  # Sprite of a Pokemon in the battle
  class PokemonSprite < ShaderedSprite
    include GoingInOut
    include MultiplePosition
    include Shader::CreatureShaderLoader
    # Constant giving the deat Delta Y (you need to adjust that so your screen animation are OK when Pokemon are KO)
    DELTA_DEATH_Y = 32
    # Sound effect corresponding to the status
    STATUS_SE = {
      poison: 'moves/poison',
      toxic: 'moves/poison',
      confusion: 'moves/confusion',
      sleep: 'moves/asleep',
      freeze: 'moves/freeze',
      paralysis: 'moves/paralysis',
      burn: 'moves/burn',
      attract: 'moves/attract'
    }

    # Tone according to the status
    STATUS_TONE = {
      neutral: [0, 0, 0, 0, 0],
      poison: [0.4, 0, 0.49, 0.6, 0],
      toxic: [0.4, 0, 0.49, 0.6, 0],
      freeze: [0.23, 0.56, 1, 0.6, 0.6],
      paralysis: [0.39, 0.47, 0, 0.6, 0],
      burn: [0.45, 0, 0, 0.8, 0],
      confusion: [0, 0, 0, 0, 0],
      sleep: [0, 0, 0, 0, 0],
      ko: [0, 0, 0, 0, 0],
      flinch: [0, 0, 0, 0, 0],
      attract: [0, 0, 0, 0, 0]
    }

    # Sound played by the shiny animation
    SHINY_SE = 'se_shiny'

    # Sound played when the stat rise up
    STAT_RISE_UP = 'moves/stat_rise_up'

    # Sound played when the stat fall down
    STAT_FALL_DOWN = 'moves/stat_fall_down'

    # Tell if the sprite is currently selected
    # @return [Boolean]
    attr_accessor :selected
    # Tell if the sprite is temporary showed while in the Substitute state
    # @return [Boolean]
    attr_accessor :temporary_substitute_overwrite
    # Get the Pokemon shown by the sprite
    # @return [PFM::PokemonBattler]
    attr_reader :pokemon
    # Get the animation handler
    # @return [Yuki::Animation::Handler{ Symbol => Yuki::Animation::TimedAnimation}]
    attr_reader :animation_handler
    # Get the position of the pokemon shown by the sprite
    # @return [Integer]
    attr_reader :position
    # Get the bank of the pokemon shown by the sprite
    # @return [Integer]
    attr_reader :bank
    # Get the scene linked to this object
    # @return [Battle::Scene]
    attr_reader :scene
    # Get the animation linked to a status tone
    # @return [Yuki::TimedLoopAnimation]
    attr_accessor :animation_tone
    # Stop the animation linked to the status tone
    # @return [Boolean]
    attr_accessor :stop_status_tone
    # Stop the gif animation
    # @return [Boolean]
    attr_accessor :stop_gif_animation

    # Create a new PokemonSprite
    # @param viewport [Viewport]
    # @param scene [Battle::Scene]
    def initialize(viewport, scene)
      super(viewport)
      create_shadow
      @animation_handler = Yuki::Animation::Handler.new
      @bank = 0
      @position = 0
      @scene = scene
      @stop_status_tone = false
      @stop_gif_animation = false
    end

    # Update the sprite
    def update
      @animation_handler.update
      @gif&.update(bitmap) unless pokemon&.dead? || pokemon&.status == 5 || @stop_gif_animation
      @animation_tone&.update unless @stop_status_tone
      @shiny_animation&.update
    end

    # Tell if the sprite animations are done
    # @return [Boolean]
    def done?
      return @animation_handler.done?
    end

    # Set the Pokemon
    # @param pokemon [PFM::PokemonBattler]
    def pokemon=(pokemon)
      @pokemon = pokemon
      if pokemon
        @position = pokemon.position
        @bank = pokemon.bank
        load_battler
        reset_position
      end
    end

    # Play the cry of the Pokemon
    # @param dying [Boolean] if the Pokemon is dying
    def cry(dying = false)
      return unless pokemon

      Audio.se_play(pokemon.cry, 100, dying ? 80 : 100)
    end

    # Set the origin of the sprite & the shadow
    # @param ox [Numeric]
    # @param oy [Numeric]
    # @return [self]
    def set_origin(ox, oy)
      @shadow.set_origin(ox, oy)
      super
    end

    # Set the zoom of the sprite
    # @param zoom [Float]
    def zoom=(zoom)
      @shadow.zoom = zoom
      super
    end

    # Set the position of the sprite
    # @param x [Numeric]
    # @param y [Numeric]
    # @return [self]
    def set_position(x, y)
      @shadow.set_position(x, y)
      super
    end

    # Set the y position of the sprite
    # @param y [Numeric]
    def y=(y)
      @shadow.y = y
      super
    end

    # Set the x position of the sprite
    # @param x [Numeric]
    def x=(x)
      @shadow.x = x
      super
    end

    # Set the opacity of the sprite
    # @param opacity [Integer]
    def opacity=(opacity)
      @shadow.opacity = opacity
      super
    end

    # Set the bitmap of the sprite
    # @param bitmap [Texture]
    def bitmap=(bitmap)
      @shadow.bitmap = bitmap
      super
    end

    # Set the visibility of the sprite
    # @param visible [Boolean]
    def visible=(visible)
      @shadow.visible = visible
      super
    end

    # Creates the flee animation
    # @return [Yuki::Animation::TimedAnimation]
    def flee_animation
      bx = enemy? ? viewport.rect.width + width : -width
      ya = Yuki::Animation
      animation = ya.move(0.5, self, x, y, bx, y)
      animation.parallel_add(ya::ScalarAnimation.new(0.5, self, :opacity=, 255, 0))
      animation.parallel_add(ya.se_play('fleee', 100, 60))
      animation.start
      animation_handler[:in_out] = animation
    end

    # Creates the switch to substitute animation
    def switch_to_substitute_animation
      base_x = x
      bx = enemy? ? viewport.rect.width + width : -width
      ya = Yuki::Animation
      animation = ya.move(substitute_animations_speed, self, x, y, bx, y)
      animation.play_before(ya.send_command_to(self, :switch_to_substitute_sprite))
      animation.play_before(ya.send_command_to(self, :reset_position))
      animation.play_before(ya.move(substitute_animations_speed, self, bx, y, base_x, y))
      animation.start
      animation_handler[:to_substitute] = animation
    end

    # Creates the switch from substitute animation
    def switch_from_substitute_animation
      base_x = x
      bx = enemy? ? viewport.rect.width + width : -width
      ya = Yuki::Animation
      animation = ya.move(substitute_animations_speed, self, x, y, bx, y)
      animation.play_before(ya.send_command_to(self, :load_battler, true))
      animation.play_before(ya.send_command_to(self, :reset_position))
      animation.play_before(ya.send_command_to(self, :stop_status_tone=, false))
      animation.play_before(ya.move(substitute_animations_speed, self, bx, y, base_x, y))
      animation.start
      animation_handler[:from_substitute] = animation
    end

    # Create a shiny animation
    def shiny_animation
      return unless @pokemon.shiny?

      ya = Yuki::Animation
      shiny = SpriteSheet.new(viewport, *shiny_dimension)
      shiny.bitmap = RPG::Cache.animation(shiny_filename)
      shiny.set_origin(width / 2, height / 2)
      cells = (shiny.nb_x * shiny.nb_y).times.map { |i| [i % shiny.nb_x, i / shiny.nb_x] }
      if Battle::BATTLE_CAMERA_3D
        shiny.shader = Shader.create(:fake_3d)
        @scene.visual.sprites3D.append(shiny)
        shiny.shader.set_float_uniform('z', shader_z_position)
      end

      # Create the animation
      animation = ya.se_play(SHINY_SE)
      animation.play_before(ya.move(0, shiny, x - 27, y - 54, x - 27, y - 54))
      animation.play_before(Yuki::Animation::SpriteSheetAnimation.new(1.5, shiny, cells))
      animation.play_before(ya.send_command_to(shiny, :dispose))
      animation.start

      @shiny_animation = animation
    end

    # Create a status animation
    # @param status [Symbol]
    def status_animation(status)
      return if under_substitute_effect?

      ya = Yuki::Animation
      status = Configs.states.symbol(status) if status.is_a?(Integer)

      sprite = UI::StatusAnimation.new(viewport, status, @bank)
      sprite.animation_coordinates(@position, @scene.battle_info.vs_type)
      status_duration = sprite.status_duration

      set_tone_status(status)

      animation = ya.se_play(STATUS_SE[status])
      animation.play_before(ya.scalar(status_duration, sprite, :animation_progression=, 0, 1))
      animation.play_before(ya.send_command_to(sprite, :dispose))
      animation.start
      animation_handler[:status_animation] = animation
    end

    # Create a tone status animation
    # @param status [Symbol or Integer] corresponding to the status of the sprite
    # @param switch [Boolean] tell if the method is called from a switch
    def set_tone_status(status, switch = false)
      return remove_tone_animation if status == 0 && switch
      return if status.nil?
      return unless @animation_tone.nil?

      ya = Yuki::Animation
      status = Configs.states.symbol(status) if status.is_a?(Integer)
      tone = STATUS_TONE[status]
      return if tone == [0, 0, 0, 0, 0]
      return if Configs.states.symbol(@pokemon.status) != status

      max_alpha = tone[3]
      min_alpha = tone[4]
      @stop_status_tone = false

      color_updater = proc do |alpha|
        self.shader.set_float_uniform('color', tone[0..2] + [alpha])
      end

      @animation_tone = ya::TimedLoopAnimation.new(4)
      @animation_tone.play_before(ya.scalar(2, color_updater, :call, min_alpha, max_alpha))
      @animation_tone.play_before(ya.scalar(2, color_updater, :call, max_alpha, min_alpha))
      @animation_tone.resolver = self
      @animation_tone.start
    end

    # Create a stat change animation
    def change_stat_animation(amount)
      ya = Yuki::Animation

      # Create the sprite and set the element
      sprite = UI::StatAnimation.new(viewport, amount, z, @bank)
      sprite.animation_coordinates(@position, @scene.battle_info.vs_type)

      # animation stat change
      animation = ya.se_play(stat_se(amount))
      animation.play_before(ya.scalar(1.5, sprite, :animation_progression=, 0, 1))
      animation.play_before(ya.send_command_to(sprite, :dispose))
      animation.start
      animation_handler[:stat_change] = animation
    end

    # remove tone animation
    def remove_tone_animation
      @animation_tone = nil
      self.shader.set_float_uniform('color', [0, 0, 0, 0])
    end

    # Set a tone on the PokemonSprite
    # @param red [Float]
    # @param green [Float]
    # @param blue [Float]
    # @param alpha [Float]
    def set_tone_to(r, g, b, alpha)
      @stop_status_tone = true
      shader.set_float_uniform('color', [red, green, blue, alpha])
    end

    # Reset the tone inflicted by the animation
    def reset_tone_status
      @stop_status_tone = false
      shader.set_float_uniform('color', [0, 0, 0, 0])
      set_tone_status(pokemon.status, true)
    end

    # Tell if the Pokemon represented by this sprite is under the effect of Substitute
    # @return [Boolean]
    def under_substitute_effect?
      return pokemon&.effects&.has?(:substitute)
    end

    # Directly switch the PokemonSprite appearance to the substitute appearance
    def switch_to_substitute_sprite
      remove_instance_variable(:@gif) if instance_variable_defined?(:@gif)
      self.shader.set_float_uniform('color', [0,0,0,0])
      set_bitmap(bank == 0 ? 'pokeback/substitute' : 'pokefront/substitute', :pokedex)
      @stop_status_tone = true
    end

    # Return the Substitute animations speed
    # @return [Float]
    def substitute_animations_speed
      return 0.2
    end

    # Pokemon sprite zoom
    # @return [Integer]
    def sprite_zoom
      return 1
    end

    # Move the camera to the battler sprite
    # @param use_position [Boolean] if the position should be used
    # @note can't send resolved parameter through Visual so PokemonSprite is used as an intermediary
    def center_camera(use_position = true)
      return false unless Battle::BATTLE_CAMERA_3D

      @scene.visual.center_target(@bank, use_position ? @position : -1)
    end

    private

    def create_shadow
      @shadow = ShaderedSprite.new(viewport)
      @shadow.shader = Shader.create(:battle_shadow)
    end

    # Reset the battler position
    def reset_position
      set_position(*sprite_position)
      self.z = basic_z_position
      set_origin(width / 2, height)
    end

    # Return the basic z position of the battler
    def basic_z_position
      z = @pokemon.bank == 0 ? 501 : 101
      z += @pokemon.position
      return z
    end

    # Get the base position of the Pokemon in 1v1
    # @return [Array(Integer, Integer)]
    def base_position_v1
      return 242, 138 if enemy?

      return 78, 184
    end

    # Get the base position of the Pokemon in 2v2+
    # @return [Array(Integer, Integer)]
    def base_position_v2
      return 202, 133 if enemy?

      return 58, 179
    end

    # Get the offset position of the Pokemon in 2v2+
    # @return [Array(Integer, Integer)]
    def offset_position_v2
      return 60, 10
    end

    # Load the battler of the Pokemon
    # @param forced [Boolean] if we force the loading of the battler (useful with Substitute cases)
    def load_battler(forced = false)
      return if under_substitute_effect? && !temporary_substitute_overwrite && !forced

      if forced || @last_pokemon&.id != @pokemon.id || @last_pokemon&.form != @pokemon.form || @last_pokemon&.code != @pokemon.code
        bitmap.dispose if @gif
        remove_instance_variable(:@gif) if instance_variable_defined?(:@gif)
        gif = pokemon.bank != 0 ? pokemon.gif_face : pokemon.gif_back
        if gif
          @gif = gif
          self.bitmap = Texture.new(gif.width, gif.height)
          gif.draw(bitmap)
        else
          self.bitmap = pokemon.bank != 0 ? pokemon.battler_face : pokemon.battler_back
        end
        load_shader(@pokemon)
      end
      @last_pokemon = @pokemon.clone
      set_tone_status(@pokemon.status, true)
    end

    # Creates the go_in animation (Exiting the ball)
    # @return [Yuki::Animation::TimedAnimation]
    def go_in_animation
      no_ball_trainer = $game_switches[Yuki::Sw::BT_NO_BALL_ANIMATION] && enemy?
      return follower_go_in_animation if pokemon.is_follower || no_ball_trainer

      return regular_go_in_animation
    end

    # Creates the go_out animation (Entering the ball if not KO, shading out if KO)
    # @return [Yuki::Animation::TimedAnimation]
    def go_out_animation
      return ko_go_out_animation if pokemon.dead?
      return follower_go_out_animation if pokemon.is_follower

      return regular_go_out_animation
    end

    # Creates the go_in animation of a "follower" pokemon
    # @return [Yuki::Animation::TimedAnimation]
    def follower_go_in_animation
      x, y = sprite_position
      bx = enemy? ? viewport.rect.width + width : -width
      $game_switches[Yuki::Sw::BT_NO_BALL_ANIMATION] = false if enemy?
      ya = Yuki::Animation
      animation = ya.send_command_to(self, :visible=, true)
      animation.play_before(ya.send_command_to(self, :set_tone_status, @pokemon.status, true))
      animation.play_before(ya.send_command_to(self, :zoom=, sprite_zoom))
      animation.play_before(ya.send_command_to(self, :opacity=, 255))
      animation.play_before(ya.move(0.1, self, bx, y, x, y))
      animation.play_before(ya.send_command_to(self, :cry))
      animation.play_before(ya.send_command_to(self, :shiny_animation))
      return animation
    end

    # Creates the regular go in animation (not follower)
    # @return [Yuki::Animation::TimedAnimation]
    def regular_go_in_animation
      ya = Yuki::Animation
      animation = ya.send_command_to(self, :visible=, true)
      animation.play_before(ya.send_command_to(self, :zoom=, 0))
      animation.play_before(ya.send_command_to(self, :opacity=, 255))
      animation.play_before(ya.send_command_to(self, :set_position, *sprite_position))
      animation.play_before(ya.send_command_to(self, :set_tone_status, @pokemon.status, true))
      poke_out = ya.scalar(0.1, self, :zoom=, 0, sprite_zoom)
      ball_animation = enemy? ? enemy_ball_animation(poke_out) : actor_ball_animation(poke_out)
      animation.play_before(ball_animation)
      animation.play_before(ya.send_command_to(self, :cry))
               .parallel_play(ya.wait(0.3))
      animation.play_before(ya.send_command_to(self, :shiny_animation))

      return animation
    end

    # Creates the go_out animation of a "follower" pokemon
    # @return [Yuki::Animation::TimedAnimation]
    def follower_go_out_animation
      x, y = sprite_position
      bx = enemy? ? viewport.rect.width + width : -width
      return Yuki::Animation.move(0.1, self, x, y, bx, y)
    end

    # Creates the regular go out animation (not follower)
    # @return [Yuki::Animation::TimedAnimation]
    def regular_go_out_animation
      ya = Yuki::Animation
      animation = ya.send_command_to(self, :zoom=, sprite_zoom)
      animation.play_before(go_back_ball_animation(ya.scalar(0.1, self, :zoom=, sprite_zoom, 0)))

      return animation
    end

    # Create the go_out animation of a KO pokemon
    # @return [Yuki::Animation::TimedAnimation]
    def ko_go_out_animation
      ya = Yuki::Animation
      animation = ya.send_command_to(self, :cry, true)
      going_down = ya.opacity_change(0.1, self, opacity, 0)
      animation.play_before(going_down)
      going_down.parallel_add(ya.move(0.1, self, x, y, x, y + DELTA_DEATH_Y))

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
      animation.parallel_play(ya.move(0.5, sprite, -sprite.ball_offset_y, y - sprite.trainer_offset_y, x, y - sprite.ball_offset_y))
      animation.parallel_play(ya.scalar(0.5, sprite, :throw_progression=, 0, 1))
      animation.parallel_play(ya.se_play(*sending_ball_se))
      animation.play_before(ya.se_play(*opening_ball_se))
      animation.play_before(ya.scalar(0.1, sprite, :open_progression=, 0, 1))
      animation.play_before(ya.send_command_to(sprite, :dispose))
      animation.play_before(pokemon_going_out_of_ball_animation)

      return animation
    end

    # Create the ball animation of the enemy Pokemon
    # @param pokemon_going_out_of_ball_animation [Yuki::Animation::TimedAnimation]
    # @return [Yuki::Animation::TimedAnimation]
    def enemy_ball_animation(pokemon_going_out_of_ball_animation)
      sprite = UI::ThrowingBallSprite.new(viewport, @pokemon)
      sprite.set_position(*sprite_position)
      sprite.y -= sprite.ball_offset_y
      ya = Yuki::Animation
      animation = ya.wait(0.2)
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
      sprite.y -= sprite.ball_offset_y
      ya = Yuki::Animation
      animation = ya.wait(0.2)
      animation.play_before(ya.se_play(*back_ball_se))
      animation.play_before(ya.scalar(0.1, sprite, :open_progression=, 0, 1))
      animation.play_before(ya.send_command_to(sprite, :dispose))
      animation.play_before(pokemon_going_in_the_ball_animation)

      return animation
    end

    # SE played when the ball is sent
    # @return [String]
    def sending_ball_se
      return 'fall'
    end

    # SE played when the ball is opening
    # @return [String]
    def opening_ball_se
      return 'pokeopen'
    end

    # SE played when the Pokemon back to the ball
    # @return [String]
    def back_ball_se
      return 'pokeopen'
    end

    # Filename for the shiny animation
    # @return [String]
    def shiny_filename
      return 'shiny'
    end

    # Sound played when the stat change
    # @return [String]
    def stat_se(amount)
      filename = amount > 0 ? STAT_RISE_UP : STAT_FALL_DOWN
      return filename
    end

    # Dimension of the shiny animation files
    # @return [Array(Integer, Integer)]
    def shiny_dimension
      return 12, 10
    end
  end
end
