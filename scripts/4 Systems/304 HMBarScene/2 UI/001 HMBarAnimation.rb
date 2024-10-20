module UI
  # Module holding all the HMBarScene UI elements
  module HMBarScene
    # HMBarAnimation UI element
    class HMBarAnimation < SpriteStack
      # Create a new HMBarAnimation UI
      # @param viewport [Viewport]
      # @param reason [Symbol] db_symbol of the HM move
      def initialize(viewport, reason)
        super(true)
        @viewport = viewport
        @reason = reason
        @animation = nil
        create_sprites
        create_animation
      end
      
      # Tell if the animation is done
      def done?
        return true unless @animation
        
        return @animation.done?
      end
      
      # Update the HMBarAnimation UI
      def update
        @animation&.update
      end
      
      private
      
      # Function that creates all the sprites of the animation
      def create_sprites
        create_hidden_move_background
        create_character_sprite
        create_pkmn_sprite
        create_hidden_move_strobes
      end
      
      # Function that creates the different backgrounds
      # The background is divided in 5 parts, to get the properly animation at the end
      # Resources are stored in graphics\transitions
      def create_hidden_move_background
        push_sprite(@background_01 = Sprite.new(@viewport).load('hidden_move_background_01', :transition))
        push_sprite(@background_02 = Sprite.new(@viewport).load('hidden_move_background_02', :transition))
        push_sprite(@background_03 = Sprite.new(@viewport).load('hidden_move_background_03', :transition))
        push_sprite(@background_04 = Sprite.new(@viewport).load('hidden_move_background_04', :transition))
        push_sprite(@background_05 = Sprite.new(@viewport).load('hidden_move_background_05', :transition))
        @background_01.opacity = @background_02.opacity = @background_03.opacity = @background_04.opacity = @background_05.opacity = 0
      end
      
      # Function that creates the character sprite
      # Resources are stored in graphics\transitions
      def create_character_sprite
        push_sprite(@character = SpriteSheet.new(@viewport, 4, 4))
        @character.set_position(145, 102)
        filename = "#{$game_player.charset_base}_#{$game_switches[Yuki::Sw::Gender] ? 'f' : 'm'}_pokecenter"
        @character.load(filename, :character)
        @character.select(3, 2)
        @character.opacity = 0
      end
      
      # Function that creates the bar strobes.
      def create_hidden_move_strobes
        push_sprite(@strobes = Sprite.new(@viewport))
        @strobes.load('hidden_move_strobes_01', :transition)
        @strobes.opacity = 0
      end
      
      # Functions that creates the pokemon sprite
      # Sprite of the Pokemon
      def create_pkmn_sprite
        @pkmn_sprite = add_sprite(416, 168, NO_INITIAL_IMAGE, type: PokemonFaceSprite)
        if @reason.is_a?(PFM::Pokemon)
          @pokemon = @reason
          @pkmn_sprite.data = @reason
        else
          @index = hm_user_index
          @index = @index.is_a?(Array) ? @index.first : @index
          @pkmn_sprite.data = @pokemon = $actors[@index]
        end
      end
      
      # User index of the selected Pokemon
      # @return []
      def hm_user_index
        return PFM.game_state.pokemon_skill_index(@reason)
      end
      
      # Function that create the pre-animation (battleback + character).
      def create_fading_in_anim
        ya = Yuki::Animation
        anim = ya.scalar(0.01, @background_01, :opacity=, 0, 255)
        anim.play_before(ya.scalar(0.01, @background_02, :opacity=, 0, 255))
        anim.play_before(ya.scalar(0.01, @background_03, :opacity=, 0, 255))
        anim.play_before(ya.scalar(0.01, @background_04, :opacity=, 0, 255))
        anim.play_before(ya.scalar(0.01, @background_05, :opacity=, 0, 255))
        anim.play_before(ya.scalar(0.04, @character, :opacity=, 0, 255))
        return anim
      end
      
      # Function that create the animation (strobes on screen + end of animation).
      def create_animation
        ya = Yuki::Animation
        anim = ya.wait(0.01)
        anim.play_before(create_fading_in_anim)
        anim.play_before(ya.send_command_to(@strobes, :opacity=, 255))
        anim.parallel_play(create_bar_loop_animation)
        anim.play_before(ya.move(1, @pkmn_sprite, 416, 168, 160, 168, distortion: :SMOOTH_DISTORTION))
        anim.play_before(create_leave_animation)
        anim.play_before(create_fading_out_anim)
        anim.start
        @animation = anim
      end
      
      # Method that creates the bar loop animation
      # @return Yuki::Animation::TimedLoopAnimation
      def create_bar_loop_animation
        ya = Yuki::Animation
        anim = ya.timed_loop_animation(0.5)
        movement = ya.move(0.5, @strobes, -320, 0, 0, 0)
        anim.parallel_play(movement)
        return anim
      end
      
      # Method that creates the opacity fading animation
      # @return Yuki::Animation::TimedAnimation
      def create_fading_out_anim
        ya = Yuki::Animation
        anim = ya.wait(0.01)
        anim.play_before(ya.opacity_change(0.01, @strobes, 255, 0))
        anim.play_before(ya.opacity_change(0.01, @character, 255, 0))
        anim.play_before(ya.opacity_change(0.04, @background_05, 255, 0))
        anim.play_before(ya.opacity_change(0.04, @background_04, 255, 0))
        anim.play_before(ya.opacity_change(0.04, @background_03, 255, 0))
        anim.play_before(ya.opacity_change(0.04, @background_02, 255, 0))
        anim.play_before(ya.opacity_change(0.04, @background_01, 255, 0))
        return anim
      end
      
      # Function that create the strobes loop animation, the cry animation and the end of the Pkmn sprite animation.
      def create_leave_animation
        ya = Yuki::Animation
        leave_animation = ya.wait(0.01)
        leave_animation.play_before(ya.se_play(@pokemon.cry.sub('Audio/SE/', ''), volume = 100, pitch = 100))
        leave_animation.play_before(ya.wait(0.5))
        leave_animation.play_before(ya.move(1, @pkmn_sprite, 160, 168, -96, 168, distortion: :SMOOTH_DISTORTION))
        return leave_animation
      end
    end
  end
end
