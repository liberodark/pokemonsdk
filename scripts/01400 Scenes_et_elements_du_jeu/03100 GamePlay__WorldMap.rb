#encoding: utf-8

#noyard
# Forme du data : 2D Array [[], [], ...] = col1, col2, col3
# Si une colonne est à nil, elle ne contient pas de données
# Si une ligne d'une colone est à nil, la zone est 0
module GamePlay
  class WorldMap < Base
    BitmapOffset = 8
    TileSize = 8
    InfoBoxColor = Color.new(128, 128, 128, 128)
    BackColor = Color.new(26, 129, 229)
    TriggerList = [:DOWN, :UP, :LEFT, :RIGHT]
    DeltaFrame = 4
    CoolDown = 5
    def initialize(mode = :view)
      super(true)
      @mode = mode
      init_sprites
      retreive_bounds
      retreive_player_coords
      @counter = 0
      @cooldown = 0
      $scene.sprite_set_visible = false if $scene.class == ::Scene_Map
    end

    def update
      return @running = false if Input.trigger?(:B)
      if @mode == :fly and Input.trigger?(:A)
        fly_attempt
      end
      update_position if direction_trigger or @counter % DeltaFrame == 0
      update_cursor(@counter += 1)
    end

    def update_position
      @cooldown -= 1 if @cooldown > 0
      if(@cooldown != 0 and @cooldown != CoolDown)
        return
      end
      x, y = @x, @y

      case Input.dir4
      when 2
        @y += 1
        @y = @y_max - 1 if @y >= @y_max
      when 8
        @y -= 1
        @y = 0 if @y < 0
      when 6
        @x += 1
        @x = @x_max - 1 if @x >= @x_max
      when 4
        @x -= 1
        @x = 0 if @x < 0
      end

      if @x != x or @y != y
        update_infobox
        calculate_cursor_coords
      end
    end

    def direction_trigger
      TriggerList.each do |i|
        if Input.trigger?(i)
          @cooldown = CoolDown + 1
          return true
        end
      end
      false
    end

    def update_cursor(counter)
      if(counter == 30)
        @cursor.src_rect.y = @cursor.src_rect.height
      elsif(counter >= 60)
        @cursor.src_rect.y = @counter = 0
      end
    end

    def fly_attempt
      zone = $env.get_zone(@x,@y)
      if(zone and zone.warp_x and zone.warp_y and $env.visited_zone?(zone))
        map_id = zone.map_id
        map_id = map_id.first unless map_id.is_a?(Numeric)
        $game_variables[::Yuki::Var::TMP1] = map_id
        $game_variables[::Yuki::Var::TMP2] = zone.warp_x
        $game_variables[::Yuki::Var::TMP3] = zone.warp_y
        $game_temp.common_event_id = 15
        return_to_scene(Scene_Map)
      end
    end

    def init_sprites
      @viewport = Viewport.create(:main, 2000)
      @back = Sprite.new(@viewport).set_bitmap("world_map_back", :interface)
      @map_sprite = Sprite.new(@viewport).set_bitmap("world_map", :interface)#Yuki::Utils.create_sprite(@viewport, "World_map", 0, 0, 1)
      @map_sprite.set_position((320 - @map_sprite.width) / 2, (240 - @map_sprite.height) / 2)
      @cursor = Sprite.new(@viewport).set_bitmap("WM_cursor", :interface)
        .set_rect_div(0, 0, 1, 2)#Yuki::Utils.create_sprite(@viewport, "WM_cursor", 0, 0, 2, src_rect_div: [0, 0, 1, 2])
      x = @map_sprite.x
      y = @map_sprite.y
      x = 0 if x < 0
      y = 0 if y < 0
      @infobox = Text.new(0, @viewport, 
        x + BitmapOffset,
        y + BitmapOffset - Text::Util::FOY,
        @map_sprite.width - 2 * BitmapOffset, 16, nil.to_s)
    end

    def retreive_player_coords
      zone_id = $env.master_zone >= 0 ? $env.master_zone : $env.get_current_zone
      @x, @y = $env.get_zone_pos(zone_id)
      @x ||= 0
      @y ||= 0
      update_infobox
      init_player_sprite
      calculate_cursor_coords
    end

    def calculate_cursor_coords
      @cursor.x = BitmapOffset + @map_sprite.x + TileSize * @x
      @cursor.y = BitmapOffset + @map_sprite.y + TileSize * @y
      max_x = @viewport.rect.width / TileSize * TileSize - TileSize
      max_y = @viewport.rect.height / TileSize * TileSize - TileSize
      if @cursor.x < 0
        @player_sprite.ox = @map_sprite.ox = @cursor.ox = @cursor.x
      elsif @cursor.x >= max_x
        @player_sprite.ox = @map_sprite.ox = @cursor.ox = @cursor.x - max_x
      end
      if @cursor.y < 0
        @player_sprite.oy = @map_sprite.oy = @cursor.oy = @cursor.y
      elsif @cursor.y >= max_y
        @player_sprite.oy = @map_sprite.oy = @cursor.oy = @cursor.y - max_y
      end
    end

    def retreive_bounds
      @x_max = (@map_sprite.width - 2 * BitmapOffset) / TileSize
      @y_max = (@map_sprite.height - 2 * BitmapOffset) / TileSize
    end

    def update_infobox
      zone = $env.get_zone(@x,@y)
      if(zone)
        @infobox.visible = true
        #@infobox.bitmap.clear
        #@infobox.bitmap.fill_rect(0, 0, @infobox.width, 16, InfoBoxColor)
        if @mode == :fly and zone.warp_x and zone.warp_y
          color = $env.visited_zone?(zone) ? 3 : 2
        else
          color = 0
        end
        @infobox.text = zone.map_name
        @infobox.load_color(color)#@infobox.bitmap.draw_shadow_text(1, 0, @infobox.width, 16, zone.map_name, 0, color)
      else
        @infobox.visible = false
      end
    end

    def init_player_sprite
      @cursor.x = BitmapOffset + @map_sprite.x + TileSize * @x
      @cursor.y = BitmapOffset + @map_sprite.y + TileSize * @y
      @player_sprite = Sprite::WithColor.new(@viewport).set_bitmap("WM_cursor", :interface)
        .set_rect_div(0, 0, 1, 2)
        .set_position(@cursor.x, @cursor.y)#Yuki::Utils.create_sprite(@viewport, "WM_cursor", 0, 0, 2, src_rect_div: [0, 0, 1, 2])
        .set_color([0, 0, 1, 1])
    end

    def dispose
      super
      @viewport.dispose
      @__last_scene.sprite_set_visible = true if @__last_scene.class == ::Scene_Map
    end
  end
end
