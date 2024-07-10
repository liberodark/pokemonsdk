module Configs
  # Definition of the scene title config
  class SceneTitleConfig
    # Get the intro movie map id
    # @return [Integer] 0 = No intro movie
    attr_accessor :intro_movie_map_id
    # Get the duration of the title music before it restarts
    # @return [Integer] duration in pcm samples
    attr_accessor :bgm_duration
    # Get the name of the bgm to play
    # @return [String]
    attr_accessor :bgm_name
    # Get the information if the language selection is enabled or not
    # @return [Boolean]
    attr_accessor :language_selection_enabled
    # Get the additional splash played after the PSDK splash
    # @return [Array<String>]
    attr_accessor :additional_splashes
    # Get the duration the controls has to wait before showing
    # @return [Float]
    attr_accessor :control_wait
  end

  module Project
    # Allow SceneTitleConfig from being accessed from Project::SceneTitle
    SceneTitle = SceneTitleConfig
  end

  # @!method self.scene_title_config
  #   @return [SceneTitleConfig]
  register(:scene_title_config, 'scene_title_config', :json, true, SceneTitleConfig)
end
