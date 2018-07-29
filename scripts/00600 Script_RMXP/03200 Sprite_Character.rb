#encoding: utf-8

# Class that describe a Character Sprite on the Map
class Sprite_Character < RPG::Sprite
  # Zoom conversion array
  ZoomDiv=[1,2,1,2/3.0,1,1]
  # Tag that disable shadow
  Shadow_Tag = "§"
  # Name of the shadow file
  Shadow_File = "0 Ombre Translucide"
  # Tag that add 1 to the superiority of the Sprite_Character
  Sup_Tag = "¤"
  # Character displayed by the Sprite_Character
  # @return [Game_Character]
  attr_accessor :character
  # Return the Sprite bush_depth
  # @return [Integer]
  attr_reader :bush_depth
  # Initialize a new Sprite_Character
  # @param viewport [Viewport] the viewport where the sprite will be shown
  # @param character [Game_Character, Game_Event, Game_Player] the character shown
  def initialize(viewport, character = nil)
    super(viewport)
    @bush_depth_sprite = Sprite.new(viewport)
    @bush_depth_sprite.opacity = 128
    @height = 0
    init(character)
  end
  # Initialize the specific parameters of the Sprite_Character (shadow, add_z etc...)
  # @param character [Game_Character, Game_Event, Game_Player] the character shown
  def init(character)
    @character = character
    if @shadow
      @shadow.dispose
      @shadow = nil
    end
    @bush_depth_sprite.visible = false
    @bush_depth = 0
    a = character.instance_variable_get(:@event)
    if(a and a.name.index(Sup_Tag)==0)
      @add_z = 2
    elsif($game_switches[::Yuki::Sw::CharaShadow])
      @add_z = 0
      if(!a or a.name.index(Shadow_Tag)!=0)
        init_shadow
      end
    else
      @add_z = 0
    end
    self.zoom = 1#$zoom_factor
    @zoom = (zoom = ::Config::Specific_Zoom) ? zoom : ZoomDiv[1]#$zoom_factor.to_i]
    @tile_id = 0
    @character_name = nil
    @pattern = 0
    @direction = 0
    update
  end
  # Update every informations about the Sprite_Character
  def update
    #>On update RPG::Sprite uniquement si il y a une animation.
    super if @_animation or @_loop_animation
    # Vérification du changement de character
    if @character_name != @character.character_name or @tile_id != @character.tile_id
      @tile_id = @character.tile_id
      @character_name = @character.character_name
      if(@tile_id >= 384)
        self.bitmap = RPG::Cache.tileset($game_map.tileset_name)
        tile_id = @tile_id - 384
        tlsy = tile_id / 8 * 32
        max_size = Graphics::MAX_TEXTURE_SIZE
        self.src_rect.set((tile_id % 8 + tlsy / max_size * 8) * 32, tlsy % max_size, 32, @height = 32)
        self.zoom = 0.5#_x=self.zoom_y=(16*$zoom_factor)/32.0
        self.ox = 16
        self.oy = 32
        @ch = 32
      else
        self.bitmap = RPG::Cache.character(@character_name, 0)
        @cw = bitmap.width / 4
        @height = @ch = bitmap.height / 4
        self.ox = @cw / 2
        self.oy = @ch
        self.zoom = 1 if self.zoom_x != 1
        self.src_rect.set(@character.pattern * @cw, (@character.direction - 2) / 2 * @ch, 
        @cw, @ch)
        @pattern = @character.pattern
        @direction = @character.direction
      end
    end
    # Position du chara sur l'écran
    _x = self.x = @character.screen_x / @zoom
    y = @character.screen_y
    if add = @character.in_swamp
      y += add == 1 ? 4 : 8
    end
    _y = self.y = y / @zoom
    # Pseudo anti-lag
    _x -= self.ox
    _y -= self.oy
    rc = self.viewport.rect
    if _x > rc.width or _y > rc.height or (_x + self.width) < 0 or (_y + self.height) < 0
      @shadow.visible = false if @shadow
      return self.visible = false
    else
      self.visible = true
    end

    #Modification du morceau du character à afficher
    if(@tile_id == 0)
      eax = @character.pattern
      if(@pattern != eax)
        self.src_rect.x = eax*@cw
        @pattern = eax
      end
      eax=@character.direction
      if(@direction != eax)
        self.src_rect.y=(eax - 2) / 2 * @ch
        @direction=eax
      end
    end

    # Superiorité
    self.z = (@character.screen_z(@ch) + @add_z)# / @zoom
    # Modification des propriétés d'affichage
#    self.blend_type = @character.blend_type
    self.bush_depth = @character.bush_depth
    #>Devons nous supprimer la transparence du héros ? 
    #Ca aurait très bien pu être fait avec l'opacité, 
    #c'est con d'utiliser un truc qui touche uniquement le héros sur tous les charas :/
    self.opacity = (@character.transparent ? 0 : @character.opacity)
    # Animation
    if @character.animation_id != 0
      $data_animations    = load_data("Data/Animations.rxdata") unless $data_animations
      animation = $data_animations[@character.animation_id]
      animation(animation, true)
      @character.animation_id = 0
    end

    update_bush_depth if @bush_depth > 0
    update_shadow if @shadow
  end
  # Update the bush depth effect
  def update_bush_depth
    bsp = @bush_depth_sprite
    bsp.z = self.z
    bsp.x = self.x
    bsp.y = self.y
    bsp.zoom = self.zoom_x
    if bsp.bitmap != self.bitmap
      bsp.bitmap = self.bitmap
    end
    rc = bsp.src_rect
    h = @height
    bd = @bush_depth / 2
    (rc2 = self.src_rect).height = h - bd
    bsp.ox = self.ox
    bsp.oy = bd
    rc.set(rc2.x, rc2.y + rc2.height, rc2.width, bd)
  end
  # Update the shadow
  def update_shadow
    @shadow.opacity = self.opacity
    @shadow.x = @character.shadow_screen_x
    @shadow.y = @character.shadow_screen_y
    @shadow.z = self.z - 1
    @shadow.visible = !@character.jumping? #> Ajout saut
  end
  # Initialize the shadow display
  def init_shadow
    @shadow = Sprite.new(self.viewport)
    @shadow.bitmap = bmp = RPG::Cache.character(Shadow_File)
    @shadow.src_rect.set(0,0, bmp.width / 4, bmp.height / 4)
    @shadow.ox = bmp.width / 8
    @shadow.oy = bmp.height / 4
  end
  # Dispose the Sprite_Character and its shadow
  def dispose
    super
    @shadow.dispose if @shadow
    @bush_depth_sprite.dispose
  end
  # Change the bush_depth
  # @param v [Integer]
  def bush_depth=(v)
    @bush_depth = v.to_i
    unless @bush_depth_sprite.visible = @bush_depth > 0
      self.src_rect.height = @height
      self.oy = @height
    end
  end
end
