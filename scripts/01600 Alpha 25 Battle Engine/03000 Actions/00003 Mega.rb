module Battle
  module Actions
    # Class describing the Mega Evolution action
    class Mega < Base
      # Get the user of this action
      # @return [PFM::PokemonBattler]
      attr_reader :user
      # Create a new mega evolution action
      # @param scene [Battle::Scene]
      # @param user [PFM::PokemonBattler]
      # @param mega_tool [Symbol] tool used to allow the trainer to use Mega
      def initialize(scene, user, mega_tool)
        super(scene)
        @user = user
        @mega_tool = mega_tool
      end

      # Compare this action with another
      # @param other [Base] other action
      # @return [Integer]
      def <=>(other)
        return 1 if other.is_a?(HighPriorityItem)
        return 1 if other.is_a?(Attack) && Attack.from(other).pursuit_enabled
        return 1 if other.is_a?(Item)
        return 1 if other.is_a?(Switch)
        return Mega.from(other).user.spd <=> @user.spd if other.is_a?(Mega)

        return -1
      end

      # Execute the action
      def execute
        # TODO!
      end
    end
  end
end
