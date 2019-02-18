module GamePlay
  # Class showing the basic World Map (TownMap) with navigation
  #
  # The world map is stored inside a 2D Array ($game_data_map) that holds each columns of the world map.
  # Each of these columns contain the ID of the zones at the y position of the cursor
  class WorldMap < Base
    # Offset of the World Map bitmap
    BitmapOffset = 8
    # Size of a tile in the WorldMap (Used outside of the script !)
    TileSize = 8
    # Color of the background of the InfoBox
    InfoBoxColor = Color.new(200, 200, 200, 128)
    # Color of the background of the Worldmap scene
    BackColor = Color.new(26, 129, 229)
    # List of the Input.trigger?/repeat? key to navigate in the WorldMap (DOWN UP LEFT RIGHT)
    TriggerList = %i[DOWN UP LEFT RIGHT]
    # Number of frame to wait before updating the position once again
    DeltaFrame = 4
    # Number of frame to wait before we can move on the map screen
    CoolDown = 5

    # Create a new World Map view
    # @param mode [Symbol] mode of the World Map (:view / :fly)
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

    # Update the scene
    def update
      return @running = false if Input.trigger?(:B)
      return fly_attempt if @mode == :fly && Input.trigger?(:A)
      update_position if direction_trigger || (@counter % DeltaFrame) == 0
      update_cursor(@counter += 1)
    end

    # Update the position of the cursor on the screen and then update the information shown
    def update_position
      @cooldown -= 1 if @cooldown > 0
      return if @cooldown != 0 && @cooldown != CoolDown

      last_x = @x
      last_y = @y
      update_cursor_position_dir4

      # If the position changed we update the info boxes
      if @x != last_x || @y != last_y
        update_infobox
        calculate_cursor_coords
      end
    end

    # Update the cursor position using Input.dir4
    def update_cursor_position_dir4
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
    end

    # Detect when we use a trigger direction so we put a little cooldown (to prevent fast traveling)
    def direction_trigger
      TriggerList.each do |i|
        if Input.trigger?(i)
          @cooldown = CoolDown + 1
          return true
        end
      end
      return false
    end

    # We update the cursor animation
    # @param counter [Integer] current value of the counter
    def update_cursor(counter)
      if counter == 30
        @cursor.src_rect.y = @cursor.src_rect.height
      elsif counter >= 60
        @cursor.src_rect.y = @counter = 0
      end
    end

    # We try to fly to the selected zone
    def fly_attempt
      zone = $env.get_zone(@x, @y)
      if zone&.warp_x && zone&.warp_y && $env.visited_zone?(zone)
        map_id = zone.map_id
        map_id = map_id.first unless map_id.is_a?(Numeric)
        $game_variables[::Yuki::Var::TMP1] = map_id
        $game_variables[::Yuki::Var::TMP2] = zone.warp_x
        $game_variables[::Yuki::Var::TMP3] = zone.warp_y
        $game_temp.common_event_id = 15
        return_to_scene(Scene_Map)
      end
    end

    # Create all the map sprites
    def init_sprites
      @viewport = Viewport.create(:main, 2000)
      @back = Sprite.new(@viewport).set_bitmap('world_map_back', :interface)
      @map_sprite = Sprite.new(@viewport).set_bitmap('world_map', :interface)
      @map_sprite.set_position((320 - @map_sprite.width) / 2, (240 - @map_sprite.height) / 2)
      @cursor = Sprite.new(@viewport).set_bitmap('WM_cursor', :interface).set_rect_div(0, 0, 1, 2)
      x = @map_sprite.x
      y = @map_sprite.y
      x = 0 if x < 0
      y = 0 if y < 0
      @info_back = Sprite.new(@viewport).set_bitmap(Bitmap.new(@map_sprite.width - 2 * BitmapOffset, 16))
      @info_back.bitmap.fill_rect(0, 0, @map_sprite.width - 2 * BitmapOffset, 16, InfoBoxColor)
      @info_back.bitmap.update
      @info_back.visible = false
      @info_box = Text.new(0, @viewport, x + BitmapOffset + 2, y + BitmapOffset - Text::Util::FOY,
                           @map_sprite.width - 2 * BitmapOffset, 16, nil.to_s)
      @info_back.set_position(@info_box.x - 2, @info_box.y + Text::Util::FOY)
    end

    # Method that retreive the player coordinates and then position him on the world map
    def retreive_player_coords
      zone_id = $env.master_zone >= 0 ? $env.master_zone : $env.get_current_zone
      @x, @y = $env.get_zone_pos(zone_id)
      @x ||= 0
      @y ||= 0
      update_infobox
      init_player_sprite
      calculate_cursor_coords
    end

    # Method that calculate the right coordinate of the cursor (preventing the cursor from going outside of the screen)
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

    # Method retreiving the boundaries of the worldmap
    def retreive_bounds
      @x_max = (@map_sprite.width - 2 * BitmapOffset) / TileSize
      @y_max = (@map_sprite.height - 2 * BitmapOffset) / TileSize
    end

    # Method updating the infobox sprites
    def update_infobox
      zone = $env.get_zone(@x, @y)
      if zone
        @info_box.visible = true
        @info_back.visible = true
        if @mode == :fly && zone.warp_x && zone.warp_y
          color = $env.visited_zone?(zone) ? 3 : 2
        else
          color = 0
        end
        @info_box.text = zone.map_name
        @info_box.load_color(color)
      else
        @info_back.visible = @info_box.visible = false
      end
    end

    # Method creating the player sprite on the world map
    def init_player_sprite
      @cursor.x = BitmapOffset + @map_sprite.x + TileSize * @x
      @cursor.y = BitmapOffset + @map_sprite.y + TileSize * @y
      @player_sprite = Sprite::WithColor.new(@viewport).set_bitmap('WM_cursor', :interface)
      @player_sprite.set_rect_div(0, 0, 1, 2)
                    .set_position(@cursor.x, @cursor.y)
                    .set_color([0, 0, 1, 1])
    end

    # Dispose the scene
    def dispose
      @info_back.bitmap.dispose
      super
      @__last_scene.sprite_set_visible = true if @__last_scene.class == ::Scene_Map
    end
  end
end
