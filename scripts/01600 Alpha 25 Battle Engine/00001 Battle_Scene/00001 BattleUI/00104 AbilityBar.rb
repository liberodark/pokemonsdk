module BattleUI
  # Sprite of a Trainer in the battle
  class AbilityBar < UI::SpriteStack
    include UI
    include GoingInOut
    include MultiplePosition
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

    # Create a new Ability Bar
    # @param viewport [Viewport]
    # @param scene [Battle::Scene]
    # @param bank [Integer]
    # @param position [Integer]
    def initialize(viewport, scene, bank, position)
      super(viewport)
      @scene = scene
      @bank = bank
      @position = position
      @animation_handler = Yuki::Animation::Handler.new
      create_sprites
      set_position(*sprite_position)
    end

    # Update the animations
    def update
      @animation_handler.update
    end

    # Tell if the animations are done
    # @return [Boolean]
    def done?
      return @animation_handler.done?
    end

    private

    # Get the base position of the Pokemon in 1v1
    # @return [Array(Integer, Integer)]
    def base_position_v1
      return 177, 145 if enemy?

      return 2, 59
    end
    alias base_position_v2 base_position_v1

    # Get the offset position of the Pokemon in 2v2+
    # @return [Array(Integer, Integer)]
    def offset_position_v2
      return 0, 38
    end

    # Creates the go_in animation
    # @return [Yuki::Animation::TimedAnimation]
    def go_in_animation
      origin_x = enemy? ? @viewport.rect.width : -@background.width

      animation = Yuki::Animation.move_discreet(0.1, self, origin_x, y, *sprite_position)
      animation.play_before(Yuki::Animation.wait(1.2))
      animation.play_before(go_out_animation)

      return animation
    end

    # Creates the go_out animation
    # @return [Yuki::Animation::TimedAnimation]
    def go_out_animation
      target_x = enemy? ? @viewport.rect.width : -@background.width

      return Yuki::Animation.move_discreet(0.1, self, *sprite_position, target_x, y)
    end

    def create_sprites
      create_background
      create_text
      create_icon
    end

    def create_background
      @background = add_sprite(0, 0, NO_INITIAL_IMAGE, type: Background)
    end

    def create_text
      add_text(*text_coordinates, 0, 16, :ability_name, color: 10, type: SymText)
    end

    def text_coordinates
      return enemy? ? [41, 10] : [14, 10]
    end

    def create_icon
      add_sprite(*icon_coordinates, NO_INITIAL_IMAGE, false, type: PokemonIconSprite)
    end

    def icon_coordinates
      return enemy? ? [2, 1] : [107, 1]
    end

    # Class showing the right background depending on the pokemon
    class Background < ShaderedSprite
      # Set the Pokemon Data
      # @param pokemon [PFM::Pokemon]
      def data=(pokemon)
        return unless (self.visible = pokemon)

        set_bitmap(background_filename(pokemon), :interface)
      end

      def background_filename(pokemon)
        return 'battle/ability_bar_enemy' if pokemon.bank != 0
        return 'battle/ability_bar_actor' if pokemon.from_party?

        return 'battle/ability_bar_ally'
      end
    end
  end
end
