#encoding: utf-8

#noyard
module GamePlay
  class Sumary < Base
    BGS = ["Detail_A","Detail_A_Egg","Detail_B","Detail_C","Detail_D_Ribbon"]
    ShaderColNone = Color.new(0, 0, 0, 0)#[0.0, 0.0, 0.0, 0.0]
    ShaderColSwitch = Color.new(0, 0, 255, 255)#[0.0, 0.0, 1.0, 1.0]
    attr_accessor :skill_selected
    def initialize(pokemon, z=1000, mode=:view, party=[], extend_data = nil)
      super(false, z*10)
      @pokemon = pokemon
      @mode = mode
      @party = party
      @index = (mode==:skill ? 2 : 0)
      @sub_index = 0
      @sub_index2 = nil
      @skill_selected = -1
      @skill_index = 0
      @extend_data = extend_data

      @viewport = Viewport.create(:main, z)

      @bg = Sprite.new(@viewport)
      #> Init the stacks
      (@stacks = [
        A.new(viewport),
        B.new(viewport),
        C.new(viewport),
        D.new(viewport)
      ]).each { |stack| stack.visible = false }
      @last_stack = @stacks.first
      #> Top sprites (always shown)
      @sprite = Sprite.new(@viewport)
        .set_position(109, 3)
      @sprite_team = Array.new(6) do |i|
        Sprite.new(@viewport)
        .set_position(287, 87 + i * 28 - 32) # + 16, 48
      end
      @sprite_team[0].set_position(192, 28 - 32)
      @ball = Sprite.new(@viewport)
        .set_position(1, 15)
      @skill_selector2 = Sprite.new(@viewport)
        .set_bitmap("Detail_Selector", :interface)
        .set_position(5, 0)
      @skill_selector = Sprite::WithColor.new(@viewport)
        .set_bitmap("Detail_Selector", :interface)
        .set_position(5, 0)
        .set_color(ShaderColNone)
    end

    def main_begin
      draw_scene
      super
    end

    def update
      super
      if(@mode==:view)
        if(@index != 2)
          if(Input.trigger?(:DOWN))
            move_party(1)
          elsif(Input.trigger?(:UP))
            move_party(-1)
          elsif(Input.trigger?(:RIGHT))
            @index+=1
            @index = 3 if @index == 2
            @index = 0 if @index > 3
            draw_scene
          elsif(Input.trigger?(:LEFT))
            @index-=1
            @index = 3 if @index < 0
            @index = 1 if @index == 2
            draw_scene
          end
        end
        if(Input.trigger?(:A))
          if(@index==1)
            @index=2
            draw_scene
          elsif(@sub_index2 and @index==2)
            ss=@pokemon.skills_set
            if(ss[@sub_index2] and ss[@sub_index])
              ss[@sub_index2],ss[@sub_index]=ss[@sub_index],ss[@sub_index2]
              @sub_index2=nil
              draw_scene
            end
          elsif(@index==2 and !$game_temp.in_battle)
            @sub_index2=@sub_index
            draw_scene
          end
        elsif(Input.trigger?(:B))
          if(@index==2)
            @index=1
            draw_scene
          else
            @running=false
          end
        end
      end
      if(@index==2)
        if(Input.trigger?(:UP))
          @sub_index-=1
          @sub_index=3 if @sub_index<0
          draw_scene
        elsif(Input.trigger?(:DOWN))
          @sub_index+=1
          @sub_index=0 if @sub_index>3
          draw_scene
        elsif(@mode==:skill)
          if(Input.trigger?(:A))
            if skill = @pokemon.skills_set[@sub_index]
              if(@extend_data)
                if(@extend_data[:on_skill_choice].call(skill))
                  @extend_data[:on_skill_use].call(skill) if @extend_data[:on_skill_use]
                  @extend_data[:skill_selected] = @skill_selected = @sub_index 
                  @running=false
                else
                  display_message(_parse(22, 108))
                end
              else
                @skill_selected=@sub_index 
                @running=false
              end
            end
          elsif(Input.trigger?(:B))
            @skill_selected=-1
            @running=false
          end
        end
      end

    end

    def draw_scene
      draw_party
      @skill_selector.visible = @skill_selector2.visible = false
      index = @pokemon.egg ? 0 : @index
      @ball.bitmap = RPG::Cache.ball(@pokemon.ball_sprite)
      @ball.src_rect.set(0,78,16,26)
      stack = @stacks[index]
      @last_stack.data = nil if stack != @last_stack
      stack.data = @pokemon
      @last_stack = stack
      @sub_index2 = nil if index != 2
      case index
      when 0
        @bg.bitmap=RPG::Cache.interface(BGS[@pokemon.egg ? 1 : 0])
      when 1
        @bg.bitmap=RPG::Cache.interface(BGS[2])
      when 2
        @bg.bitmap=RPG::Cache.interface(BGS[3])
        draw_C(stack)
      when 3
        @bg.bitmap=RPG::Cache.interface(BGS[4])
      end
    end

    def draw_C(stack)
      @skill_selector.visible = true
      @skill_selector.y = 109 + 32 * @sub_index
      if(@sub_index2)
        @skill_selector2.visible = true
        @skill_selector2.set_position(@skill_selector.x, 109 + 32 * @sub_index2)
        @skill_selector.set_color(ShaderColSwitch)
      else
        @skill_selector.set_color(ShaderColNone)
      end
      skill = @pokemon.skills_set[@sub_index]
      stack.skill_stack.each_value { |sprite| sprite.data = skill }
    end

    def draw_party
      draw_party_proc = proc do |i, pos|
        if(pkm = @party[(i + pos) % @party.size])
          @sprite_team[i].bitmap = pkm.icon
          @sprite_team[i].visible = true
        end
      end
      # Update the party and Pokemon sprite
      @sprite.bitmap = @pokemon.battler_face
      @sprite.src_rect.set(8, 16, 80, 80)
      @sprite_team.each { |i| i.visible = false }
      if(pos = @party.index(@pokemon))
        @party.size.times { |i| draw_party_proc.call(i, pos) }
      end
    end

    def move_party(add)
      pos = @party.index(@pokemon)
      if(pos)
        pokemon = @party[(pos + add) % @party.size]
        @pokemon = pokemon if pokemon
      else
        @pokemon=@party[0] if @party[0]
      end
      draw_scene
    end

    def dispose
      super
      # @viewport.dispose
    end
  end
end
