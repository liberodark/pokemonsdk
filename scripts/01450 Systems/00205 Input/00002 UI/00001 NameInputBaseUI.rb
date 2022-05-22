module UI
  class NameInputBaseUI < GenericBase
    alias create_button_background void
    alias update_background_animation void

    private

    def create_background
      @background = UI::BlurScreenshot.new($scene.__last_scene)
      $scene.add_disposable(@background)
    end

    def create_control_button
      @ctrl = []
    end
  end
end
