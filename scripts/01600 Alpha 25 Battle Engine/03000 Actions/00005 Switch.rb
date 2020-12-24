module Battle
  module Actions
    # Class describing the usage of switching out a Pokemon
    class Switch < Base
      # Get the Pokemon who's being switched
      # @return [PFM::PokemonBattler]
      attr_reader :who
      # Create a new switch action
      # @param scene [Battle::Scene]
      # @param who [PFM::PokemonBattler] who's being switched out
      # @param with [PFM::PokemonBattler] with who the Pokemon is being switched
      def initialize(scene, who, with)
        super(scene)
        @who = who
        @with = with
      end

      # Compare this action with another
      # @param other [Base] other action
      # @return [Integer]
      def <=>(other)
        return 1 if other.is_a?(HighPriorityItem)
        return 1 if other.is_a?(Attack) && Attack.from(other).pursuit_enabled
        return 1 if other.is_a?(Item)
        return Switch.from(other).who.spd <=> @who.spd if other.is_a?(Switch)

        return -1
      end

      # Execute the action
      def execute
        visual = @scene.visual
        # @type [BattleUI::PokemonSprite]
        (sprite = visual.battler_sprite(@who.bank, @who.position)).go_out
        visual.hide_info_bar(@who)
        wait_for(sprite, visual)
        # Logically switching the Pokemon
        @scene.logic.switch_battlers(@who, @with)
        # Switching the sprite
        sprite.pokemon = @with
        sprite.go_in
        visual.show_info_bar(@with)
        wait_for(sprite, visual)
        @scene.logic.switch_handler.execute_switch_events(@who, @with)
      end

      private

      # Wait for the sprite animation to be done
      # @param sprite [#done?]
      # @param visual [Battle::Visual]
      def wait_for(sprite, visual)
        until sprite.done?
          visual.update
          Graphics.update
        end
      end
    end
  end
end
