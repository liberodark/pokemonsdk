#encoding: utf-8

# Display everything that should be displayed during the Scene_Map
class Spriteset_Map
  # Retreive the Game Player sprite
  # @return [Sprite_Character]
  attr_reader :game_player_sprite
  # Initialize a new Spriteset_Map object
  # @param zone [Integer, nil] the id of the zone where the player is
  def initialize(zone = nil)
    #>On reset la globale zoom_factor pour éviter les problèmes
#    $zoom_factor = Graphics.get_zoom_factor
    # ビューポートを作成
    @viewport1 = Viewport.create(:main, 0)
    @viewport2 = Viewport.create(:main, 200)
    @viewport3 = Viewport.create(:main, 5000)
    init_tilemap
    init_panorama_fog
    init_psdk_add
    init_characters
    init_player
    init_weather_picture_timer
    finish_init(zone)
  end
  # Do the same as initialize but without viewport initialization (opti)
  # @param zone [Integer, nil] the id of the zone where the player is
  def reload(zone = nil)
    dispose_sp_map if(@sp_bg)
    init_tilemap
    init_psdk_add
    init_characters
    init_player
    finish_init(zone)
  end
  # Last step of the Spriteset initialization
  # @param zone [Integer, nil] the id of the zone where the player is
  def finish_init(zone)
    # フレーム更新
    create_panel(zone)
    Yuki::TJN.force_update_tone
    Yuki::TJN.update
    Yuki::MapLinker.load_buildings
    update
    Graphics.sort_z
  end
  # Tilemap initialization
  def init_tilemap
    # タイルマップを作成
    #>Adapter en fonction du jeu, sur Pokémon SDK 2x2 => 32x32
    tilemap_class = Yuri_Tilemap#((::Config::Yuri_Tilemap_Disabled or $zoom_factor == 2) ? Tilemap : Yuri_Tilemap)
    if @tilemap.class != tilemap_class
      @tilemap.dispose if @tilemap
      @tilemap = tilemap_class.new(@viewport1)
    end
    @tilemap.tileset = RPG::Cache.tileset($game_map.tileset_name)
    7.times do |i|
      filename = $game_map.autotile_names[i] + '_._tiled'
      unless RPG::Cache.autotile_exist?(filename)
        Converter.convert_autotile("graphics/autotiles/#{$game_map.autotile_names[i]}.png") unless $game_map.autotile_names[i].empty?
      end
      filename = $game_map.autotile_names[i] unless RPG::Cache.autotile_exist?(filename)
      @tilemap.autotiles[i] = RPG::Cache.autotile(filename)
    end
    @tilemap.map_data = $game_map.data
    @tilemap.priorities = $game_map.priorities
    @tilemap.reset
  end
  # Panorama and fog initialization
  def init_panorama_fog
    # パノラマプレーンを作成
    @panorama = Plane.new(@viewport1)
    @panorama.z = -1000
    # フォグプレーンを作成
    @fog = Plane.new(@viewport1)
    @fog.z = 3000
  end
  # PSDK related thing initialization
  def init_psdk_add
    #Particles System Add
    Yuki::Particles::init(@viewport1)
    Yuki::Particles::set_on_teleportation(true)
    Yuki::FollowMe::init(@viewport1)
  end
  # Sprite_Character initialization
  def init_characters
    # キャラクタースプライトを作成
    if character_sprites = @character_sprites
      $game_map.events.size.upto(character_sprites.size - 1) do |i|
        character_sprites[i].dispose
        character_sprites[i] = nil
      end
      character_sprites.compact!
      i = -1
      $game_map.events.each_value do |event|
        character = character_sprites[i += 1]
        event.particle_push
        if character
          character.init(event)
        else
          character_sprites[i] = Sprite_Character.new(@viewport1, event)
        end
      end
      return
    end
    @character_sprites = character_sprites = []
    $game_map.events.each_value do |event|
      sprite = Sprite_Character.new(@viewport1, event)
      event.particle_push
      character_sprites.push(sprite)
    end
  end
  # Player initialization
  def init_player
    #FollowMeSection
    Yuki::FollowMe::update
    Yuki::FollowMe::particle_push
    @character_sprites.push(@game_player_sprite = Sprite_Character.new(@viewport1, $game_player))
    $game_player.particle_push
    Yuki::Particles::update
    Yuki::Particles::set_on_teleportation(false)
  end
  # Weather, picture and timer initialization
  def init_weather_picture_timer
    # 天候を作成
    @weather = RPG::Weather.new(@viewport1)
    # ピクチャを作成
    @picture_sprites = []
    for i in 1..50
      @picture_sprites.push(Sprite_Picture.new(@viewport2,
        $game_screen.pictures[i]))
    end
    # タイマースプライトを作成
    @timer_sprite = Sprite_Timer.new
  end
  # Spriteset_map dispose
  # @param from_warp [Boolean] if true, prepare a screenshot with some conditions and cancel the sprite dispose process
  # @return [Sprite, nil] a screenshot or nothing
  def dispose(from_warp = false)
    if($game_switches[Yuki::Sw::WRP_Transition] and $scene.class == Scene_Map and from_warp)
      sp = Sprite.new(@viewport3)
      sp.z = 10**6
      sp.bitmap = Graphics.snap_to_bitmap
      sp.x = Graphics.width/2
      sp.ox = sp.bitmap.width / 2
      sp.y = Graphics.height/2
      sp.oy = sp.bitmap.height / 2
      if(Config.const_defined?(:ScreenScale))
        sp.zoom = 1.0 / Config::ScreenScale
      end
      return sp
    end
    return nil if from_warp
    #puts "Spriteset_Map.dispose called"
    # タイルマップを解放
    #@tilemap.tileset.dispose
    7.times do |i|
      #@tilemap.autotiles[i].dispose
    end
    @tilemap.dispose
    # パノラマプレーンを解放
    @panorama.dispose
    # フォグプレーンを解放
    @fog.dispose
    # キャラクタースプライトを解放
    for sprite in @character_sprites
      sprite.dispose
    end
    @game_player_sprite = nil
    # 天候を解放
    @weather.dispose
    # ピクチャを解放
    for sprite in @picture_sprites
      sprite.dispose
    end
    # タイマースプライトを解放
    @timer_sprite.dispose
    # ビューポートを解放
    @viewport1.dispose
    @viewport2.dispose
    @viewport3.dispose
    dispose_sp_map if(@sp_bg)
    #>Suppression des SystemTag
#    Yuki::SystemTag.dispose
    return nil
  end
  # Update every sprite
  def update
    #>Mise à jour des system tag
#    Yuki::SystemTag.update
    update_panorama_fog
    # タイルマップを更新
    @tilemap.ox = $game_map.display_x / 4
    @tilemap.oy = $game_map.display_y / 4
    @tilemap.update
    Yuki::FollowMe::update
    update_events
    update_weather_picture
    # タイマースプライトを更新
    @timer_sprite.update
    # 画面の色調とシェイク位置を設定
    @viewport1.tone = $game_screen.tone
    @viewport1.ox = $game_screen.shake
    # 画面のフラッシュ色を設定
    @viewport3.color = $game_screen.flash_color
    # ビューポートを更新
    @viewport1.update
    @viewport3.update
    update_panel
    @viewport1.sort_z unless Graphics.skipping_frame?
  end
  # update event sprite
  def update_events
    if $game_map.event_erased
      @character_sprites.each(&:update)
      $game_map.event_erased = false
    else
      e = nil
      x = $game_player.x
      y = $game_player.y
      for sprite in @character_sprites
        e = sprite.character
        sprite.update if((e.x - x).abs <= 13 and (e.y - y).abs <= 13)
      end
    end
  end
  # update weather and picture sprites
  def update_weather_picture
    # 天候グラフィックを更新
    @weather.type = $game_screen.weather_type
    @weather.max = $game_screen.weather_max
    @weather.ox = $game_map.display_x / 4
    @weather.oy = $game_map.display_y / 4
    @weather.update
    # ピクチャを更新
    for sprite in @picture_sprites
      sprite.update
    end
  end
  # update panorama and fog sprites
  def update_panorama_fog
    # パノラマが現在のものと異なる場合
    if @panorama_name != $game_map.panorama_name# or @panorama_hue != $game_map.panorama_hue
      @panorama_name = $game_map.panorama_name
      @panorama_hue = $game_map.panorama_hue
      if @panorama.bitmap != nil
        @panorama.bitmap.dispose
        @panorama.bitmap = nil
      end
      unless @panorama_name.empty? #if @panorama_name != ""
        @panorama.bitmap = RPG::Cache.panorama(@panorama_name, @panorama_hue)
      end
      Graphics.frame_reset
    end
    # フォグが現在のものと異なる場合
    if @fog_name != $game_map.fog_name# or @fog_hue != $game_map.fog_hue
      @fog_name = $game_map.fog_name
      @fog_hue = $game_map.fog_hue
      if @fog.bitmap != nil
        @fog.bitmap.dispose
        @fog.bitmap = nil
      end
      unless @fog_name.empty? #if @fog_name != ""
        @fog.bitmap = RPG::Cache.fog(@fog_name, @fog_hue)
      end
      Graphics.frame_reset
    end
    # パノラマプレーンを更新
    @panorama.ox = $game_map.display_x / 8
    @panorama.oy = $game_map.display_y / 8
    # フォグプレーンを更新
    @fog.zoom_x = $game_map.fog_zoom / 100.0
    @fog.zoom_y = $game_map.fog_zoom / 100.0
    @fog.opacity = $game_map.fog_opacity.to_i
#    @fog.blend_type = $game_map.fog_blend_type
    @fog.ox = ($game_map.display_x / 4 + $game_map.fog_ox) / 2
    @fog.oy = ($game_map.display_y / 4 + $game_map.fog_oy) / 2
#    @fog.tone = $game_map.fog_tone
  end
  # create the zone panel of the current zone
  # @param zone [Integer, nil] the id of the zone where the player is
  def create_panel(zone)
    if(zone and $game_data_zone[zone].panel_id>0)
      @sp_bg = Sprite.new unless @sp_bg
      @sp_bg.x = 2
      @sp_bg.y = -30
      @sp_bg.z = 5001
      @sp_bg.bitmap = bmp = RPG::Cache.windowskin("Pannel_#{$game_data_zone[zone].panel_id}")
      @sp_fg = Text.new(0, nil, 2, -30 - 4, bmp.width, bmp.height, $game_data_zone[zone].map_name, 1)
      @sp_fg.load_color(10)
      @sp_fg.z = 5002
      @counter = 0
    end
  end
  # Dispose the zone panel
  def dispose_sp_map
    @sp_bg.dispose
    @sp_bg = nil
    @sp_fg.dispose
    @sp_fg = nil
  end
  # Update the zone panel
  def update_panel
    if(@sp_bg)
      @counter+=1
      if(@counter<32)
        @sp_bg.y+=1
        @sp_fg.y+=1
      elsif(@counter==154)
        dispose_sp_map
      elsif(@counter>122)
        @sp_bg.y-=1
        @sp_fg.y-=1
      end
    end
  end
  # Change the visible state of the Spriteset
  def visible=(v)
    @sp_bg.visible=v if @sp_bg
    @sp_fg.visible=v if @sp_fg
    @viewport1.visible=v
    @viewport2.visible=v
    @viewport3.visible=v
  end
  # Return the map viewport
  # @return [LiteRGSS::Viewport]
  def map_viewport
    return @viewport1
  end
end
