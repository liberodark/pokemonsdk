# How to use:
# ScriptLoader.load_tool('Rxdata2Tiled/Rxdata2Tiled')
# Rxdata2Tiled.run

module Rxdata2Tiled
  module_function

  def run
    tilesets = load_data('Data/Tilesets.rxdata')
    system_tags = load_data('Data/PSDK/SystemTags.rxdata')
    tiled_tilesets = Tileset::SPECIAL_TILESETS.values.map { |args| Tileset.new(*args) }
    tiled_tilesets.each(&:save)
    map_info = load_data('Data/MapInfos.rxdata')
    map_info.each do |id, map|
      puts "converting #{map.name}"
      Map.new(format("Data/Map%03d.rxdata", id), id, map.name, tilesets, tiled_tilesets, system_tags).save
    end
    nil
  end
end
ScriptLoader.load_tool('Rxdata2Tiled/tileset')
ScriptLoader.load_tool('Rxdata2Tiled/map')
