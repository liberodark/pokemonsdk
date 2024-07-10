module LiteRGSS
  class Text
    # Module holding few constatns that are still not in configuration file
    # TODO: Move those constants to configuration file
    module Util
      # Default outlinesize, nil gives a 0 and keep shadow processing, 0 or more disable shadow processing
      DEFAULT_OUTLINE_SIZE = nil
      # Offset induced by the Font
      FOY = 2
    end
  end
end
