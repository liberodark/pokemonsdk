module Battle
  class Visual
    class RBJ_WildTransition
      # Set the Transition in Transition mode
      def transition
        @update_method = :update_transition
        @counter = 0
        @viewport.color.set(0, 0, 0, 0)
        @viewport.sort_z
        @done = false
      end

      private

      def update_transition
        @counter += 1
        unless @counter < 180
          @battle_scene.visual.unlock
          @done = true
        end
      end
    end
  end
end
