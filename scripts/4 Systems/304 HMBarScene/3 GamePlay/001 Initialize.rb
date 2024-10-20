module GamePlay
  class HMBarScene < BaseCleanUpdate
    # Initialize the HMBarScene UI
    # @param reason [Symbol, PFM::Pokemon] symbol for the HM used, PFM::Pokemon to specify the Pokemon to use in the anim
    # @param scene_to_update [Object, nil] either an instantiated object responding to #update, or nil if no scene to update
    def initialize(reason, scene_to_update = nil)
      super()
      @reason = reason
      @scene_to_update = scene_to_update
      update_given_scene
    end
  end
end

GamePlay.hm_bar_scene_class = GamePlay::HMBarScene