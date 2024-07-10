module UI
  # Base UI for name input scenes
  class NameInputBaseUI < GenericBase
    alias create_button_background void
    alias update_background_animation void

    # @param viewport [LiteRGSS::Viewport]
    # @param last_scene [GamePlay::BaseCleanUpdate]
    def initialize(viewport, last_scene)
      @last_scene = last_scene
      super(viewport)
    end

    private

    def create_background
      @background = UI::BlurScreenshot.new(@viewport, @last_scene)
      $scene.add_disposable(@background)
    end

    def create_control_button
      @ctrl = []
    end
  end
end
