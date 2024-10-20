module GamePlay
  class HMBarScene < BaseCleanUpdate
    include UI::HMBarScene
    
    # Update the graphics of the scene
    def update_graphics
      return @running = false if @hm_bar_animation.done?

      @hm_bar_animation.update
      update_given_scene
    end

    private

    # Update the given scene to update during this one
    # Will only update if the given Object respond to the update method
    def update_given_scene
      return unless @scene_to_update.respond_to?(:update)

      @scene_to_update.update
    end

    # Create the graphics of the scene
    def create_graphics
      super
      create_hm_bar_animation
    end

    # Create the HMBarAnimation component
    def create_hm_bar_animation
      @hm_bar_animation = HMBarAnimation.new(@viewport, @reason)
    end
  end
end
