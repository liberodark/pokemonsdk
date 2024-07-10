module Battle
  module Effects
    class NoRetreat < CantSwitch
      # Get the name of the effect
      # @return [Symbol]
      def name
        return :no_retreat
      end
    end
  end
end