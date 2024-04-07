module Battle
  class Move
    class PhotonGeyser < Basic
      # Is the skill physical ?
      # @return [Boolean]
      def physical?
        best_stat = original_launcher.atk > original_launcher.ats
        log_data("Photon Geyser category: #{best_stat ? :physical : :special}")
        return best_stat
      end
      # Is the skill special ?
      # @return [Boolean]
      def special?
        return !physical?
      end
    end
    Move.register(:s_photon_geyser, PhotonGeyser)
  end
end
