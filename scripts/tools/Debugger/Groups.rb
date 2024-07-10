module Yuki
  class Debug
    # Show the Groups in debug mod
    class Groups
      # Create a new Group viewer
      # @param viewport [Viewport]
      # @param stack [UI::SpriteStack] main stack giving the coordinates to use
      def initialize(viewport, stack)
        @stack = UI::SpriteStack.new(viewport, stack.x, stack.y + 64, default_cache: :b_icon)
        @width = viewport.rect.width - stack.x
        @height = viewport.rect.height - @stack.y
      end

      # Update the view
      def update
        if $scene.is_a?(Scene_Map) && $wild_battle
          @stack.visible ||= true
          if @last_groups != $wild_battle.groups || @last_id != $game_map.map_id
            @last_groups = $wild_battle.groups
            @last_id = $game_map.map_id
            @stack.dispose
            load_groups
          end
        else
          @stack.visible &&= false
        end
      end

      # Load the groups
      def load_groups
        @stack.add_text(0, 0, 320, 16, "Zone : #{$env.get_current_zone_data&.name}", color: 9)
        load_remaining_groups(16)
      end

      # Load the remaining groups
      # @param y [Integer] initial y position
      # @return [Integer] final y position
      def load_remaining_groups(y)
        x = 0
        $wild_battle.groups.each do |group|
          break if y >= @height

          @stack.add_text(x, y, 320, 16, "#{group.system_tag} (#{group.terrain_tag}) #{group.tool}", color: 9)
          group.encounters.each do |encounter|
            female = encounter.extra[:gender] == 2
            shiny = encounter.shiny_setup.shiny
            icon_filename = PFM::Pokemon.icon_filename(data_creature(encounter.specie).id, encounter.form, female, shiny, false)
            @stack.push(x, y, icon_filename)
            x += 32
            if x >= @width
              y += 32
              x = 0
            end
            break if y >= @height
          end
          y += 32
          x = 0
        end
        return y
      end
    end
  end
end
