module Battle
  module Effects
    class Ability
      class Stalwart < Ability
        # Check if the user of this ability ignore the center of attention in the enemy bank
        # @return [Boolean]
        def ignore_target_redirection?
          return true
        end
      end
      register(:stalwart, Stalwart)
      register(:propeller_tail, Stalwart)
    end
  end
end
