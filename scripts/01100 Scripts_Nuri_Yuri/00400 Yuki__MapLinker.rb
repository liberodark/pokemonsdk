#encoding: utf-8

module Yuki
  # MapLinker, script that emulate the links between maps. This script also display events.
  # @author Nuri Yuri
  module MapLinker
    # The offset in X until we see black borders
    OffsetX = 10
    # The offset in Y until we seen black borders
    OffsetY = 7
    # The number of tiles the Maker has to let in common between each maps
    DeltaMaker = 3
    # The default Map (black borders)
    DefaultMap = RPG::Map.new(20,15)
    DefaultMap.data.fill(0)
    # The map filename format
    Map_Format = "Data/Map%03d.rxdata"
    module_function
    # Get the OffsetX
    def get_OffsetX
      return $game_switches[Sw::MapLinkerDisabled] ? 0 : OffsetX
    end
    # Get the OffsetY
    def get_OffsetY
      return $game_switches[Sw::MapLinkerDisabled] ? 0 : OffsetY
    end
    # Get the added events
    # @return [Hash<Integer => Array<RPG::Event>>] Integer is map_id
    def get_added_events
      return @added_events
    end
    # Reset the module when the RGSS resets itself
    def reset
      #  [n_id, n_addx, e_id, e_addy, s_id, s_addx, o_id, o_addy]
      @link_data = nil
      #> Définition des variables du data
      @nord_data = nil
      @est_data = nil
      @sud_data = nil
      @ouest_data = nil
      #> Données relatives à la dernière map
      @last_map = nil
      @last_map_id = nil
      @last_map_data = nil
      @last_events = nil
      #> ID du dernier event
      @last_event_id = 0
      #> Informateur de téléportation
      @warp = [OffsetY,0,0,OffsetX]
      #> Information sur les évènements ajoutés
      @added_events = Hash.new
    end
    # Load a map and its linked map
    # @param map_id [Integer] the map ID
    # @return [RPG::Map] the map adjusted
    def load_map(map_id)
      if $game_switches[Sw::MapLinkerDisabled]
        @link_data = nil
        @last_map = current_map_data = load_map_data(map_id)
        @last_map_id = map_id
        return current_map_data
      end
      #> Restauration du data d'origine de la map
      if @last_map
        @last_map.data = @last_map_data
        @last_map.events = @last_events
        @last_map.width -= OffsetX*2
        @last_map.height -= OffsetY*2
      end
      #> Chargement de la nouvelle map
      current_map_data = load_map_data(map_id).clone
      #> Génération de la grille / décallage des évents / Gestion des systemTag
      generate_map_grid(current_map_data, map_id)
      #> Chargement des données de liaison
      link_data = $game_data_maplinks[map_id]
      if link_data
        nord_data = load_map_data(link_data[0])
        est_data = load_map_data(link_data[2])
        sud_data = load_map_data(link_data[4])
        ouest_data = load_map_data(link_data[6])
      else
        nord_data = est_data = sud_data = ouest_data = load_map_data(0)
      end
      @link_data = link_data
      #> Génération des liaisons de la grille + chargement évent
      if link_data
        @added_events.clear
        generate_map_data_link(current_map_data, nord_data, est_data, 
          sud_data, ouest_data)
      end
      #> Enregistrement des données
      @nord_data = nord_data
      @est_data = est_data
      @sud_data = sud_data
      @ouest_data = ouest_data
      @last_map = current_map_data
      @last_map_id = map_id
      @warp[1] = current_map_data.data.xsize - OffsetX - DeltaMaker + 1
      @warp[2] = current_map_data.data.ysize - OffsetY - DeltaMaker + 1
      #> Chargement des musiques d'autres maps
      #autoload_sounds(map_id)
      #> Retour des données attendues
      return current_map_data
    end
    # Load the data of a map (with some optimizations)
    # @param map_id [Integer] the id of the Map
    # @return [RPG::Map]
    def load_map_data(map_id)
      return DefaultMap if map_id == 0 #> Map nulle
      return @last_map if map_id == @last_map_id #> Map d'où on vient
      if link_data = @link_data #> Une des map linké
        return @nord_data if map_id == link_data[0]
        return @est_data if map_id == link_data[2]
        return @sud_data if map_id == link_data[4]
        return @ouest_data if map_id == link_data[6]
      end
      return load_data(sprintf(Map_Format, map_id))
    end
    # Shift the map of OffsetX, OffsetY on a larger map grid
    def generate_map_grid(data, map_id)
      last_map_data = data.data
      tbl = Table.new(last_map_data.xsize + OffsetX*2, last_map_data.ysize + OffsetY*2, 3)
      tbl.fill(0)
      tag = Table.new(tbl.xsize, tbl.ysize, 3)
      x = y = z = x2 = nil
      last_event_id = 0
      ox = OffsetX
      oy = OffsetY
      #> Clonage des données avec offset
      3.times do |z|
        last_map_data.xsize.times do |x|
          x2 = x + ox
          last_map_data.ysize.times do |y|
            tbl[x2, y+oy, z] = last_map_data[x, y, z]
          end
        end
      end
      #> Recalibration des évents
      events = data.events
      nevent = Hash.new
      tmpevt = nil
      events.each do |id, event|
        nevent[id] = tmpevt = event.clone
        tmpevt.x += OffsetX
        tmpevt.y += OffsetY
        last_event_id = id if id > last_event_id
      end
      #> Redéfinition des variables
      @last_map_data = last_map_data
      @last_events = events
      @last_event_id = last_event_id
      data.events = nevent
      data.data = tbl
      data.width += OffsetX*2
      data.height += OffsetY*2
    end
    # Generate the link (tile copy / event copy)
    # @param data [RPG::Map] the current map
    # @param nord_data [RPG::Map] the north map
    # @param est_data [RPG::Map] the east map
    # @param ouest_data [RPG::Map] the west map
    def generate_map_data_link(data, nord_data, est_data, sud_data, ouest_data)
      tbl = data.data
      x = y = z = ox = oy = modulo = id = event = nevent = nil
      last_event_id = @last_event_id
      events = data.events
      link_data = @link_data
      3.times do |z|
        #> Traitement du nord
        ox = link_data[1] + OffsetX
        oy = nord_data.height - OffsetY - DeltaMaker
        modulo = nord_data.width
        data = nord_data.data
        OffsetY.times do |y|
          tbl.xsize.times do |x|
            tbl[x, y, z] = data[(x - ox)%modulo, y+oy, z]
          end
        end
        #> Traitement du sud
        ox = link_data[5] + OffsetX
        oy = tbl.ysize - OffsetY - DeltaMaker
        modulo = sud_data.width
        data = sud_data.data
        DeltaMaker.upto(OffsetY+DeltaMaker-1) do |y|
          tbl.xsize.times do |x|
            tbl[x, y+oy, z] = data[(x - ox)%modulo, y, z]
          end
        end
        #> Traitement de l'ouest
        ox = ouest_data.width - OffsetX - DeltaMaker
        oy = OffsetY + link_data[7]
        modulo = ouest_data.height
        data = ouest_data.data
        OffsetY.upto(tbl.ysize-OffsetY-1)  do |y|
          OffsetX.times do |x|
            tbl[x, y, z] = data[x + ox, (y-oy)%modulo, z]
          end
        end
        #> Traitement de l'est
        ox = tbl.xsize - OffsetX - DeltaMaker
        oy = link_data[3] + OffsetY
        modulo = est_data.height
        data = est_data.data
        OffsetY.upto(tbl.ysize-OffsetY-1) do |y|
          DeltaMaker.upto(OffsetX+DeltaMaker-1) do |x|
            tbl[x + ox, y, z] = data[x, (y - oy)%modulo, z]
          end
        end
      end
      #> Copie des évents nord
      oy = nord_data.height - OffsetY - DeltaMaker
      last_event_id = ajust_events(nord_data, oy, 
        ouest_data.height - DeltaMaker - 1, link_data[1] + OffsetX, -oy, 
        last_event_id, events, link_data[0], :y)
=begin
      ox = link_data[1] + OffsetX
      oy = nord_data.height - OffsetY - DeltaMaker
      y = ouest_data.height - DeltaMaker - 1
      nord_data.events.each do |id, event|
        if event.y.between?(oy, y)
          events[last_event_id+=1] = nevent = event.clone
          nevent.x += ox
          nevent.y -= oy
          nevent.id = last_event_id
        end
      end
=end
      #> Copie des évents sud
      last_event_id = ajust_events(sud_data, DeltaMaker, 
        OffsetY + DeltaMaker - 1, link_data[5] + OffsetX, 
        tbl.ysize - OffsetY - DeltaMaker, last_event_id, events, link_data[4], :y)
=begin
      ox = link_data[5] + OffsetX
      oy = tbl.ysize - OffsetY - DeltaMaker
      y = OffsetY + DeltaMaker - 1
      sud_data.events.each do |id, event|
        if event.y.between?(DeltaMaker,y)
          events[last_event_id+=1] = nevent = event.clone
          nevent.x += ox
          nevent.y += oy
          nevent.id = last_event_id
        end
      end
=end
      #> Copie des évents ouest
      ox = ouest_data.width - OffsetX - DeltaMaker
      last_event_id = ajust_events(ouest_data, ox, ouest_data.width - DeltaMaker - 1, 
        -ox, link_data[7] + OffsetY, last_event_id, events, link_data[6])
=begin
      oy = link_data[7] + OffsetY
      ox = ouest_data.width - OffsetX - DeltaMaker
      x = ouest_data.width - DeltaMaker - 1
      ouest_data.events.each do |id, event|
        if event.x.between?(ox, x)
          events[last_event_id+=1] = nevent = event.clone
          nevent.x -= ox
          nevent.y += oy
          nevent.id = last_event_id
        end
      end
=end
      #> Copie des évents est
      last_event_id = ajust_events(est_data, DeltaMaker, 
        OffsetX + DeltaMaker - 1, tbl.xsize - OffsetX - DeltaMaker, 
        link_data[3] + OffsetY, last_event_id, events, link_data[2])
=begin
      oy = link_data[3] + OffsetY
      ox = tbl.xsize - OffsetX - DeltaMaker
      x = OffsetX + DeltaMaker - 1
      est_data.events.each do |id, event|
        if event.x.between?(DeltaMaker, x)
          events[last_event_id+=1] = nevent = event.clone
          nevent.x += ox
          nevent.y += oy
          nevent.id = last_event_id
        end
      end
=end
    end
    # Adjust the event position and id. Move them on the current map
    # @param data [RPG::Map] the map where the event normally are
    # @param min [Integer] the min position where the event can be to be cloned
    # @param max [Integer] the max position where the event can be to be cloned
    # @param ox [Integer] the offset x of the event
    # @param oy [Integer] the offset y of the event
    # @param last_event_id [Integer] the last event id
    # @param events [Hash] the event hash of the current map
    # @param map_id [Integer] the map id of the event
    # @param type [Symbol] the property checked on the event to check if they're cloned or not
    # @return [Integer] the new last_event_id
    def ajust_events(data, min, max, ox, oy, last_event_id, events, map_id, type = :x)
      added_events = @added_events[map_id] = []
      nevent = nil
      id = nil
      event = nil
      env = $env
      data.events.each do |id, event|
        if event.send(type).between?(min, max)
          next if env.get_event_delete_state(id, map_id)
          events[last_event_id+=1] = nevent = event.clone
          nevent.x += ox
          nevent.y += oy
          nevent.id = last_event_id
          nevent.original_id = id
          nevent.original_map = map_id
          nevent.offset_x = ox
          nevent.offset_y = oy
          added_events << nevent
        end
      end
      return last_event_id
    end
    # Autoload the sounds of the other maps
    # @param map_id [Integer] id of the map the player warped
    def autoload_sounds(map_id)
      print "\rMapLinker autoload sounds...\nCommande : "
      args = []
      [@nord_data, @est_data, @sud_data, @ouest_data].each do |data|
        next unless data
        args << "audio/bgm/#{data.bgm.name.downcase}" if data.autoplay_bgm
        args << "audio/bgm/#{data.bgs.name.downcase}" if data.autoplay_bgs
      end
      Audio::Cache.autoload_sounds(map_id, *args)
    end
    # Test if the player can warp between maps and warp him
    def test_warp
      return unless @link_data
      x = $game_player.x
      y = $game_player.y
      #> Nord
      if y <= @warp[0]
        warp(@link_data[0], x - @link_data[1] - OffsetX, @nord_data.height - DeltaMaker)
      #> Est
      elsif x >= @warp[1]
        warp(@link_data[2], DeltaMaker - 2, y - @link_data[3] - OffsetY)
      #> Sud
      elsif y >= @warp[2]
        warp(@link_data[4], x - @link_data[5] - OffsetX, DeltaMaker - 2)
      #> Ouest
      elsif x <= @warp[3]
        warp(@link_data[6], @ouest_data.width - DeltaMaker, y - @link_data[7] - OffsetY)
      end
    end
    # Warp a player to a new map and a new location
    # @param map_id [Integer] the ID of the new map
    # @param x [Integer] the new x position of the player
    # @param y [Integer] the new y position of the player
    def warp(map_id, x, y)
      return if map_id == 0
      $game_temp.player_transferring = true
      $game_temp.player_new_map_id = map_id
      $game_temp.player_new_x = x + OffsetX
      $game_temp.player_new_y = y + OffsetY
      $game_temp.player_new_direction = $game_player.direction
    end
    # Load the buildings of the map (Building System)
    def load_buildings
      load_building(@last_map_id, 0, 0)
      return unless link_data = @link_data
      load_building(link_data[0], DeltaMaker, -@nord_data.height + DeltaMaker, :nord)
      load_building(link_data[2], @last_map.width - OffsetX * 2 - DeltaMaker, -DeltaMaker, :est)
      load_building(link_data[4], -DeltaMaker, @last_map.height - OffsetY * 2 - DeltaMaker, :sud)
      load_building(link_data[6], -@ouest_data.width + DeltaMaker, DeltaMaker, :ouest)
    end
    # Path of the building data
    BPath = "Data/Buildings/%03d.rxdata"
    # Load the bulding of a map
    # @param map_id [Integer] the id of the map
    # @param ox [Integer] the offset x of the map
    # @param oy [Integer] the offset y of the map
    # @param check [Symbol, false] the criteria to check to show a building
    def load_building(map_id, ox, oy, check = false)
      if File.exist?(filename = sprintf(BPath, map_id))
        mod = Particles
        arr = load_data(filename)
        arr.each do |args|
          if check
            next if !args[4] or !args[4].include?(check)
            args[1] += ox
            args[2] += oy
          end
          Particles.add_building(*args)
        end
        unless check
          parallaxe = arr.instance_variable_get(:@parallaxe)
          if parallaxe
            parallaxe.each do |args|
              Particles.add_parallax(*args)
            end
          end
        end
      end
    end
  end
end
