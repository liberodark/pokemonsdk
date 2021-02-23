module Graphics
  on_start do
    next unless RPG::Cache.icon_exist?('game')

    # @type [Yuki::VD, nil]
    windowskin_vd = RPG::Cache.instance_variable_get(:@icon_data)
    data = windowskin_vd&.read_data('game')
    # @type [Image]
    image = data ? Image.new(data, true) : Image.new('graphics/icons/game.png')
    Graphics.window.icon = image
    image.dispose
  end
end
