module UI
  class NameInputBaseUI < GenericBase
    private void_method :create_button_background
    public void_method :update_background_animation

    private

    def create_background
      last_scene = $scene.__last_scene
      vp = last_scene.is_a?(Scene_Map) ? last_scene.spriteset.map_viewport : last_scene.viewport
      snap = vp.snap_to_bitmap
      @background = ShaderedSprite.new(vp).set_bitmap(snap)
      # TODO make a default "SCREEN_BLUR_SHADER"
      @background.shader = Shader.new(Shader.load_to_string('blur'))
      @background.shader.set_float_uniform('resolution', [snap.width, snap.height])
      $scene.add_disposable(snap, @background)
    end

    def create_control_button
      @ctrl = []
    end
  end
end
