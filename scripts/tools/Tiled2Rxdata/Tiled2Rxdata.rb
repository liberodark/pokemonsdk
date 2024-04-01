# How to load:
# ScriptLoader.load_tool('Tiled2Rxdata/Tiled2Rxdata')
module Tiled2Rxdata
  GID_ANIMATED_TILES = Hash.new { |h, k| h[k] = GidAnimatedTiles.new(ANIMATED_TILES, k) }
  TILESET_FILENAME = 'Data/Tilesets.rxdata'
  TILESETS = load_data(TILESET_FILENAME)
  SYSTEM_TAGS_FILENAME = 'Data/PSDK/SystemTags.rxdata'
  SYSTEM_TAGS = load_data(SYSTEM_TAGS_FILENAME)
  MAP_INFO_FILENAME = 'Data/MapInfos.rxdata'
  MAP_INFO = load_data(MAP_INFO_FILENAME)
  ANIMATED_TILES_FILENAME = 'Data/AnimatedTiles.rxdata'
  ANIMATED_COUNTS = File.exist?(ANIMATED_TILES_FILENAME) ? load_data(ANIMATED_TILES_FILENAME) : {}
  STUDIO_ANIMATED_TILES_FILENAME = 'Data/Tiled/.jobs/animated_tiles.json'
  MAP_JOBS_FILENAME = 'Data/Tiled/.jobs/map_jobs.json'
  MIN_MS = Configs.display.tilemap_settings.autotile_idle_frame_count * 1000 / 60
  LOADED_TILESET_IMAGES = {}
  ANIMATED_COUNT_CACHE = {}

  module_function

  # Load the Studio data of a map
  # @param map_name [String] db symbol of the map to load
  # @return [Map]
  def load_map(map_name)
    return Map.new(JSON.parse(File.read("Data/Studio/maps/#{map_name}.json"), { symbolize_names: true }))
  end

  # Load the animated tiles safely
  # @return [Hash]
  def load_animated_tiles
    return {} unless File.exist?(STUDIO_ANIMATED_TILES_FILENAME)

    return JSON.parse(File.read(STUDIO_ANIMATED_TILES_FILENAME), { symbolize_names: true })
  end

  # Start the Studio -> RMXP map conversion process
  def start
    build_animated_count_cache
    jobs = JSON.parse(File.read(MAP_JOBS_FILENAME))
    new_jobs = jobs.reject { |map_name| process_map(map_name) }
    File.write(MAP_JOBS_FILENAME, JSON.dump(new_jobs))
    finalize
  end

  # Process a single map to be converted and have its animated tile generated
  # @param map_name [String] db symbol of the map to process
  # @return [Boolean] if the map was successfully processed
  def process_map(map_name)
    log_info "Processing Map #{map_name}"
    map = load_map(map_name)
    map.convert
    return true
  rescue Exception => e
    log_error "Failed to process #{map_name}: #{e.message}"
    return false
  end

  # Finalize the process (save all global files)
  # @note this function is called by start!
  def finalize
    Settings.save
    File.binwrite(SYSTEM_TAGS_FILENAME, Marshal.dump(SYSTEM_TAGS))
    File.binwrite(TILESET_FILENAME, Marshal.dump(TILESETS))
    File.binwrite(ANIMATED_TILES_FILENAME, Marshal.dump(ANIMATED_COUNTS))
    Tile::BUFFER_IMAGES.each(&:dispose)
    Tile.send(:remove_const, :BUFFER_IMAGES)
    $data_system_tags = load_data('Data/PSDK/SystemTags.rxdata') if $data_system_tags
  end

  # Build the animated counter cache to reduce the number of counter & potential desync between maps
  def build_animated_count_cache
    ANIMATED_COUNTS.each_value do |counts|
      counts.each do |count|
        next if ANIMATED_COUNT_CACHE.key?(count.waits)

        ANIMATED_COUNT_CACHE[count.waits] = count
      end
    end
  end

  ANIMATED_TILES = load_animated_tiles
end

ScriptLoader.load_tool('Tiled2Rxdata/settings')
ScriptLoader.load_tool('Tiled2Rxdata/map')
ScriptLoader.load_tool('Tiled2Rxdata/animated_tiles')
ScriptLoader.load_tool('Tiled2Rxdata/tile')

Tiled2Rxdata.start
