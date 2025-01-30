module UI
  # Handle the mega evolution animation in the battle scene
  class MegaEvolveAnimation < SpriteStack
    # Create a new MegaEvolve Spritestack
    # @param viewport [Viewport]
    # @param scene [Battle::Scene]
    # @param target [PFM::PokemonBattler]
    # @param target_sprite [BattleUI::PokemonSprite]
    def initialize(viewport, scene, target, target_sprite)
      super(viewport)
      @scene = scene
      @target = target
      @target_sprite = target_sprite
      @default_cache = :animation
      create_sprite_mega
      @ring = create_sprite(ring_filename)
      @stars = create_sprite(star_filename)
      create_icon_mega
      @all_cells = create_sprite_cells(@main_sprite)
      @cells_first = create_sprite_cells(@main_sprite, exclude_column: 1)
      @cells_second = create_sprite_cells(@main_sprite, exclude_column: 2)
      @cells_last = create_sprite_cells(@main_sprite, exclude_column: 4)
    end

    # Play the MegaEvolve animation
    def mega_evolution_animation
      ya = Yuki::Animation

      following_animation = ya.send_command_to(@target_sprite, :pokemon=, @target)
      following_animation.play_before(ya::SpriteSheetAnimation.new(0.5, @main_sprite, @cells_last))
                        .parallel_add(stars_animation)
                        .parallel_add(ring_animation)
                        .parallel_add(icon_mega_animation)
      following_animation.play_before(ya.send_command_to(@target_sprite, :cry))

      animation = ya.se_play(se_me)
      animation.play_before(ya::SpriteSheetAnimation.new(0.8, @main_sprite, @all_cells))
      animation.play_before(ya.send_command_to(@main_sprite, :load, "#{me_filename}-1", :animation))
      animation.play_before(ya::SpriteSheetAnimation.new(0.7, @main_sprite, @cells_first))
      animation.play_before(ya.send_command_to(@main_sprite, :load, "#{me_filename}-2", :animation))
      animation.play_before(ya::SpriteSheetAnimation.new(0.6, @main_sprite, @cells_second))
      animation.play_before(ya.send_command_to(@main_sprite, :load, "#{me_filename}-3", :animation))
      animation.play_before(following_animation)

      return animation
    end

    private

    # Create the ring animation
    def ring_animation
      ya = Yuki::Animation

      animation = ya.send_command_to(@ring, :opacity=, 255)
      animation.play_before(parallel_animation = ya.scalar(0.5, @ring, :zoom=, 0.7, 2.5))
      parallel_animation.play_before(ya.opacity_change(0.25, @ring, 255, 0))

      return animation
    end

    # Create the stars animation
    def stars_animation
      ya = Yuki::Animation

      animation = ya.send_command_to(@stars, :opacity=, 255)
      animation.play_before(parallel_animation = ya.scalar(0.25, @stars, :zoom=, 1, 1.5))
      parallel_animation.play_before(ya.opacity_change(0.25, @stars, 255, 0))

      return animation
    end

    # Create the icon mega animation
    def icon_mega_animation
      ya = Yuki::Animation

      animation = ya.send_command_to(@icon, :opacity=, 255)
      animation.play_before(ya.opacity_change(1.5, @icon, 255, 0))

      return animation
    end

    # Create the main Spritesheet for the animation
    def create_sprite_mega
      @main_sprite = add_sprite(@target_sprite.x, @target_sprite.y, me_filename, *me_dimension, type: SpriteSheet,
                                                                                                ox: me_sprite_origin[0], oy: me_sprite_origin[1])
      @main_sprite.zoom = 2
      apply_3d_battle_settings(@main_sprite) if Battle::BATTLE_CAMERA_3D
    end

    # Create the icon mega for the animation
    def create_icon_mega
      @icon = add_sprite(@target_sprite.x, @target_sprite.y, me_icon_filename, ox: me_icon_origin[0], oy: me_icon_origin[1])
      @icon.opacity = 0
      apply_3d_battle_settings(@icon) if Battle::BATTLE_CAMERA_3D
    end

    # Create the coordinates of the all_cells in a sprite sheet.
    # @param sprite [Sprite]
    # @param exclude_column [Integer]
    # @return [Array<Array<Integer>>]
    def create_sprite_cells(sprite, exclude_column: 0)
      all_cells = (sprite.nb_x * sprite.nb_y - exclude_column * sprite.nb_x).times.map { |i| [i % sprite.nb_x, i / sprite.nb_x] }

      return all_cells
    end

    # Create the sprite for the mega evolution animation
    # @param file [String] filename of the sprite
    def create_sprite(filename)
      sprite = add_sprite(@target_sprite.x, @target_sprite.y, filename, ox: ring_and_stars_origin[0], oy: ring_and_stars_origin[1])
      sprite.opacity = 0
      apply_3d_battle_settings(sprite) if Battle::BATTLE_CAMERA_3D

      return sprite
    end

    # Apply the 3D settings to the sprite if the 3D camera is enabled
    # @param sprite [Sprite, Spritesheet]
    def apply_3d_battle_settings(sprite)
      sprite.shader = Shader.create(:fake_3d)
      @scene.visual.sprites3D.append(sprite)
      sprite.shader.set_float_uniform('z', @target_sprite.shader_z_position)
    end

    def ring_filename
      return 'mega-evolution/mega-evolution-ring'
    end

    def star_filename
      return 'mega-evolution/mega-evolution-star'
    end

    def me_filename
      return 'mega-evolution/mega-evolution'
    end

    def me_icon_filename
      return 'mega-evolution/icon_mega'
    end

    def se_me
      return 'mega-evolution'
    end

    def ring_and_stars_origin
      return 95, 148
    end

    def me_sprite_origin
      return 64, 90
    end

    def me_icon_origin
      return 128, 140
    end

    def me_dimension
      return 8, 8
    end
  end
end