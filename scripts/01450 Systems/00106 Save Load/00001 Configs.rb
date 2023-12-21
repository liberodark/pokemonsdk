module Configs
  # Configuration of the saves
  class SaveConfig
    # Number of save the player can have
    # @return [Integer] 0 = infinite
    attr_accessor :maximum_save_count
    # Get the header of the save file (preventing other fangames to read the save if changed)
    # @return [String]
    attr_accessor :save_header
    # Get the save key (preventing other fangames to read the save if changed)
    # @return [Integer]
    attr_accessor :save_key
    # Get the base filename of the save
    # @return [String]
    attr_accessor :base_filename
    # Tell if the player is allowed to save over another save
    # @return [Boolean]
    attr_accessor :can_save_on_any_save

    # Tell if the player can have unlimited saves
    # @return [Boolean]
    def unlimited_saves?
      @maximum_save_count == 0
    end

    # Tell if the player is restricted to 1 save
    # @return [Boolean]
    def single_save?
      @maximum_save_count == 1
    end
  end

  module Project
    # Allow configuration of the saves from being accessed through the Project module
    Save = SaveConfig
  end

  # @!method self.save_config
  #   @return [SaveConfig]
  register(:save_config, 'save_config', :json, true, SaveConfig)
end
