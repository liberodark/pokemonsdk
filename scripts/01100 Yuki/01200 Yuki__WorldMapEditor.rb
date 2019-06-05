#encoding: utf-8

module Yuki
  # Module that helps the user to edit his worldmap
  module WorldMapEditor
    module_function
    # Main function
    def main
      ($tester = Tester.allocate).data_load
      $pokemon_party = PFM::Pokemon_Party.new
      $pokemon_party.expand_global_var
      select_worldmap(0)
      select_zone(0)
      init
      show_help
      Graphics.transition
      until Keyboard.press?(Keyboard::Escape)
        Graphics.update
        update
      end
      @viewport.dispose
    end
    # Affiche l'aide
    def show_help
      cc 2
      puts "list_zone : list all the zone"
      puts "list_zone(\"name\") : list the zone that match name"
      puts "select_zone(id) : Select the zone id to place the with the mouse on the map"
      puts "save : Save your modifications"
      puts "clear_map : Clear the whole map"
      puts "list_worldmap : list all the world maps"
      puts "list_worldmap(\"name\") : list the world maps that match name"
      puts "select_worldmap(id) : select the world map to edit"
      puts "add_worldmap(\"name\", \"image name\") : add the world map with the given name and the image filename without extension"
      puts "delete_worldmap(id) : delete the worldmap and its data, be sure before use this"
      puts "set_worldmap_name(id, \"new_name\") : change the name of the worldmap"
      puts "set_worldmap_image(id, \"new_image\") : change the file displayed for the world map"
      puts "set_worldmap_back(id, \"new_image\") : change the file displayed behind the worldmap"
      cc 7
    end
    # Update the scene
    def update
      wm = GamePlay::WorldMap
      #> Position update
      update_origin(wm)
      return if Mouse.x < 0 or Mouse.y < 0
      @last_x = @x
      @last_y = @y
      @x = (Mouse.x - wm::BitmapOffset) / wm::TileSize + @ox
      @y = (Mouse.y - wm::BitmapOffset) / wm::TileSize + @oy
      @map_sprite.set_origin(@ox * wm::TileSize, @oy * wm::TileSize)
      @cursor.set_position(
        (Mouse.x / wm::TileSize) * wm::TileSize, 
        (Mouse.y / wm::TileSize) * wm::TileSize)
      update_infobox if @last_x != @x or @last_y != @y
      return if @x < 0 or @y < 0
      update_zone if Mouse.press?(:left)
      remove_zone if Mouse.press?(:right)
    end
    # Update the current zone
    def update_zone
      # adjust_map
      # $game_data_map[@x][@y] = @current_zone
      $game_data_worldmap[@current_worldmap].data[@x, @y] = @current_zone
      update_infobox
    end
    # Adjust the map array data
    def adjust_map
      # unless $game_data_map[@x]
      #   $game_data_map[@x] = Array.new(@map_sprite.height / GamePlay::WorldMap::TileSize)
      # end
    end
    # Clear the map
    def clear_map
      max_x = @map_sprite.width / GamePlay::WorldMap::TileSize
      max_y = @map_sprite.height / GamePlay::WorldMap::TileSize
      # $game_data_map = Array.new(max_x) { Array.new(max_y) }
      data = Table.new(max_x, max_y)
      0.upto(data.xsize - 1) do |x|
        0.upto(data.ysize - 1) do |y|
          data[x, y] = -1
        end
      end
      $game_data_worldmap[@current_worldmap].data = data

    end
    # Remove the zone
    def remove_zone
      # adjust_map
      # $game_data_map[@x][@y] = nil
      # update_infobox
      $game_data_worldmap[@current_worldmap].data[@x, @y] = -1
      update_infobox
    end
    # Update the origin x/y
    # @param wm [Class] should contain TileSize and BitmapOffset constants
    def update_origin(wm)
      oox = @ox
      ooy = @oy
      @ox += 1 if Input.repeat?(:right)
      max_ox = (@map_sprite.width - Graphics.width + wm::BitmapOffset) / wm::TileSize
      max_ox = 1 if max_ox <= 0
      @ox = max_ox - 1 if @ox >= max_ox
      @ox -= 1 if Input.repeat?(:left)
      @ox = 0 if @ox < 0
      @oy += 1 if Input.repeat?(:down)
      max_oy = (@map_sprite.height - Graphics.height + wm::BitmapOffset) / wm::TileSize
      max_oy = 1 if max_oy <= 0
      @oy = max_oy - 1 if @oy >= max_oy
      @oy -= 1 if Input.repeat?(:up)
      @oy = 0 if @oy < 0
    end
    # Save the world map
    def save
      # Gather zone worldmap
      $game_data_worldmap.each_with_index do |worldmap, id|
        # Correct zones id
        0.upto(worldmap.data.xsize - 1) do |x|
          0.upto(worldmap.data.ysize - 1) do |y|
            worldmap.data[x, y] = -1 if worldmap.data[x, y] >= $game_data_zone.length
          end
        end
        # Set the zones
        worldmap.zone_list_from_data.each do |zone_id|
          $game_data_zone[zone_id].worldmap_id = id
        end
      end
      # Save the data
      save_data([$game_data_map, $game_data_zone],"Data/PSDK/MapData.rxdata")
      save_data($game_data_worldmap, "Data/PSDK/WorldMaps.rxdata")
      $game_system.se_play($data_system.decision_se)
    end
    # List the zone
    def list_zone(name = "")
      name = name.downcase
      $game_data_zone.each_with_index do |zone, index|
        if zone and zone.map_name.downcase.include?(name)
          puts "#{index} : #{zone.map_name}"
        end
      end
      show_help
    end
    # Select a zone
    def select_zone(id)
      @current_zone = id
      puts "#{$game_data_zone[id].map_name}"
    end
    # Select a world map
    def select_worldmap(id)
      @current_worldmap = id
      @map_sprite.set_bitmap($game_data_worldmap[id].image, :interface) if @map_sprite
      puts "World map #{$game_data_worldmap[id].name} is now selected."
    end
    # Add a new world map and select it
    def add_worldmap(name, image)
      $game_data_worldmap.push GameData::WorldMap.new(name.downcase, image)
      puts "World map added : #{name.downcase}"
      select_worldmap($game_data_worldmap.length - 1)
    end
    # Delete world map
    def delete_worldmap(id)
      if $game_data_worldmap.length <= 1
        puts "You can't delete the last world map"
        return nil
      end
      puts "World map deleted : #{$game_data_worldmap[id]&.name}"
      $game_data_worldmap.delete_at(id)
      select_worldmap(0)
    end
    # Display all worldmaps
    def list_worldmap(name = "")
      name = name.downcase
      $game_data_worldmap.each_with_index do |wm, index|
        if wm and wm.name.downcase.include?(name)
          puts "#{index} : #{wm.name}"
        end
      end
      show_help
    end
    def set_worldmap_name(id, new_name)
        new_name = new_name.downcase
        old_name = $game_data_worldmap[id].name
        $game_data_worldmap[id].name = new_name
        puts "\"#{old_name}\" has been rename to \"#{new_name}\""
    end
    def set_worldmap_image(id, new_image)
        old_img = $game_data_worldmap[id].image
        $game_data_worldmap[id].image = new_image
        @map_sprite.set_bitmap(new_image, :interface) if @current_worldmap == id
        puts "#{$game_data_worldmap[id].name}'s' image updated to #{new_image}"
    end
    def set_worldmap_back(id, new_image)
        old_img = $game_data_worldmap[id].background_image
        $game_data_worldmap[id].background_image = new_image
        puts "#{$game_data_worldmap[id].name}'s' background updated to #{new_image}"
    end
    # Init the editor
    def init
      wm = GamePlay::WorldMap
      @ox = @oy = 0 # Offset of the mapgrid
      @last_x = nil
      @last_y = nil
      @x = (Mouse.x - wm::BitmapOffset) / wm::TileSize - @ox
      @y = (Mouse.y - wm::BitmapOffset) / wm::TileSize - @oy
      init_sprites
      Object.define_method(:list_zone) { |name = ""| Yuki::WorldMapEditor.list_zone(name) }
      Object.define_method(:select_zone) { |id| Yuki::WorldMapEditor.select_zone(id) }
      Object.define_method(:save) {  Yuki::WorldMapEditor.save }
      Object.define_method(:clear_map) {  Yuki::WorldMapEditor.clear_map }
      Object.define_method(:select_worldmap) { |id| Yuki::WorldMapEditor.select_worldmap(id) }
      Object.define_method(:add_worldmap) { |name, image| Yuki::WorldMapEditor.add_worldmap(name, image) }
      Object.define_method(:delete_worldmap) { |id| Yuki::WorldMapEditor.delete_worldmap(id) }
      Object.define_method(:list_worldmap) { |name = ""| Yuki::WorldMapEditor.list_worldmap(name) }
      Object.define_method(:set_worldmap_image) { |id, value| Yuki::WorldMapEditor.set_worldmap_image(id, value) }
      Object.define_method(:set_worldmap_name) { |id, value| Yuki::WorldMapEditor.set_worldmap_name(id, value) }
      Object.define_method(:set_worldmap_back) { |id, value| Yuki::WorldMapEditor.set_worldmap_back(id, value) }
    end
    # Create the sprites
    def init_sprites
      @viewport = Viewport.create(:main, 2000)
      @map_sprite = Sprite.new(@viewport).set_bitmap($game_data_worldmap[@current_worldmap].image, :interface)
      @cursor = Sprite.new(@viewport).set_bitmap("WM_cursor", :interface)
        .set_rect_div(0, 0, 1, 2)
      @infobox = Text.new(0, @viewport, 
        @map_sprite.x + GamePlay::WorldMap::BitmapOffset,
        @map_sprite.y + GamePlay::WorldMap::BitmapOffset - Text::Util::FOY,
        @map_sprite.width - 2 * GamePlay::WorldMap::BitmapOffset, 16, nil.to_s)
    end
    # Update the infobox
    def update_infobox
      # zone = $env.get_zone(@x,@y)
      zone_id = $game_data_worldmap[@current_worldmap].data[@x, @y]
      zone = (zone_id and zone_id >= 0) ? $game_data_zone[zone_id] : nil
      if(zone)
        @infobox.visible = true
        if zone.warp_x and zone.warp_y
          color = 2
        else
          color = 0
        end
        @infobox.text = zone.map_name
        @infobox.load_color(color)
      else
        @infobox.visible = false
      end
    end
  end
end
