#encoding: utf-8

#noyard
module GamePlay
  class StorageSumary < Sumary
    def draw_party
       if(@index<3)
        @sprite.visible=true
        @sprite_team.each { |i| i.visible=true }
        @sprite.bitmap=@pokemon.battler_face
        @sprite.src_rect.set(8,8,80,80)
        pos=@party.index(@pokemon)
        if(pos)
          index=0
          pos.step(pos+5) do |i|
            if(i<@party.size)
              pkm=@party[i]
            else
              pkm=@party[i-@party.size]
            end
            if(pkm)
              @sprite_team[index].bitmap = pkm.icon
            else
              @sprite_team[index].visible=false
            end
            index+=1
          end
        end
      else
        @sprite.visible=false
        @sprite_team.each { |i| i.visible=false }
      end
    end

    def move_party(add)
      pos=@party.index(@pokemon)
      if(pos)
        pos+=add
        if(pos<0)
          pos+=@party.size
        elsif(pos>(@party.size-1))
          pos-=@party.size
        end
        pokemon=@party[pos]
        until(pokemon)
          pos+=add
          pokemon=@party[pos]
          break if pos<0
          pos=-1 if pos>(@party.size-1)
        end
        @pokemon=pokemon if pokemon
      else
        @pokemon=@party[0] if @party[0]
      end
      draw_scene
    end
  end
end
