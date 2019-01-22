#encoding: utf-8

#noyard
module GamePlay
  class BattleGrounds < Sprite
    GR_NAMES=["ground_building","ground_grass","ground_tall_grass","ground_taller_grass",
    "ground_cave","ground_mount","ground_pond","ground_sea","ground_under_water",
    "ground_ice","ground_snow","ground_sand"]
    A_Pos = [nil,[88, 157+10],[99,157+10],[99,157+10]]#1.5
    E_Pos = [nil,[233,89],[233,74],[233,74]] #1.3

    def initialize(viewport, actors = true)
      super(viewport)
      @actors = actors
      self.set_bitmap
      self.calibrate
    end

    def set_bitmap
      if($game_temp.battleback_name and $game_temp.battleback_name.size > 0) #$game_variables[id]>0
        ground_name = $game_temp.battleback_name.sub("back_","ground_")
        if(RPG::Cache.battleback_exist?(ground_name))
          self.bitmap = ::RPG::Cache.battleback(ground_name)
          self.ox = self.bitmap.width/2
          self.oy = self.bitmap.height/2
          return
        end
      end
      env=$env
      v=0
      if(env.grass?)
        v=1
      elsif(env.tall_grass?)
        v=2
      elsif(env.very_tall_grass?)
        v=3
      elsif(env.cave?)
        v=4
      elsif(env.mount?)
        v=5
      elsif(env.pond?)
        v=6
      elsif(env.sea?)
        v=7
      elsif(env.under_water?)
        v=8
      elsif(env.ice?)
        v=9
      elsif(env.snow?)
        v=10
      elsif(env.sand?)
        v=11
      end
      self.bitmap = ::RPG::Cache.battleback(GR_NAMES[v])
      self.ox = self.bitmap.width/2
      self.oy = self.bitmap.height/2
    end

    def calibrate
      arr = @actors ? A_Pos : E_Pos
      if($game_temp.vs_type == 2)
        self.zoom_x = self.zoom_y = @actors ? 2 : 1.3
      elsif(@actors)
        self.zoom_x = self.zoom_y = 1.5 if $zoom_factor == 2
      end
      self.x, self.y = *arr[$game_temp.vs_type]
    end

  end
end
