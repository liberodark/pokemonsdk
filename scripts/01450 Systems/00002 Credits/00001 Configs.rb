module Configs
  # Configuration for the Credit Scene
  class CreditsConfig
    # Get the project title splash (in grahics/titles)
    # @return [String]
    attr_accessor :project_splash
    # Get the chief project title
    # @return [String]
    attr_accessor :chief_project_title
    # Get the chief project name
    # @return [String]
    attr_accessor :chief_project_name
    # Get the other leaders
    # @return [Array<Hash>]
    attr_accessor :leaders
    # Get the game credits
    # @return [String]
    attr_accessor :game_credits
    # Get the credits bgm
    # @return [String]
    attr_accessor :bgm
    # Get the line height of credits
    # @return [Integer]
    attr_accessor :line_height
    # Get the speed of the text scrolling
    # @return [Float]
    attr_accessor :speed
    # Get the spacing between a leader text and the center of the screen
    # @return [Integer]
    attr_accessor :leader_spacing
  end

  module Project
    # Allow the credit config from being accessed through project settings
    Credits = CreditsConfig
  end

  # @!method self.credits_config
  #   @return [CreditsConfig]
  register(:credits_config, 'credits_config', :json, false, CreditsConfig)
end
