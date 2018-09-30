#encoding: utf-8

module Yuki
  # Module that manage the particle display
  # @author Nuri Yuri
  module Particles
    # ID of the variable that change the particle data id
    VAR_PARTICLE_DATA_ID = 108
    # The particle data
    Data=Array.new
    Data[0]=Hash.new
    Data[0][1]={#,:oy_offset=>-2
    :enter=>{:max_counter=>16,:data=>[{:file=>"Herbe",:rect=>[0,0,16,16],:zoom=>1,:position=>:center_pos},nil,nil,nil,{:rect=>[0,16,16,16]},nil,nil,nil,{:rect=>[0,32,16,16]},nil,nil,nil,{:rect=>[0,48,16,16]}],:loop=>false},
    :stay =>{:max_counter=>1,:data=>[{:file=>"Herbe",:zoom=>1,:position=>:center_pos,:rect=>[0,48,16,16]}],:loop=>false},
    :leave=>{:max_counter=>1,:data=>[],:loop=>false}}
    Data[0][2]={
    :enter=>{:max_counter=>8,:data=>[nil,nil,nil,{:file=>"HauteHerbe",:zoom=>1,:position=>:center_pos}],:loop=>false},
    :stay =>{:max_counter=>1,:data=>[{:file=>"HauteHerbe",:zoom=>1,:position=>:center_pos}],:loop=>false},
    :leave=>{:max_counter=>1,:data=>[],:loop=>false}}

    Data[0][:exclamation] = {
    :enter=>{:max_counter=>36,:data => 
    [{:file=>"emotions",:rect=>[0,0,16,16],:zoom=>1,:position=>:center_pos, :add_z => -1, :oy_offset => 0},
    nil,{:oy_offset => 2},
    nil,{:oy_offset => 4},
    nil,{:oy_offset => 8},
    nil,{:oy_offset => 12},
    nil,{:oy_offset => 16, :add_z => 64},
    nil,{:oy_offset => 20},
    nil,{:oy_offset => 24},
    nil,{:oy_offset => 20}],
    :loop=>false},
    :stay=>{:max_counter=>2,:data=>[{:state => :leave}], :loop=>false},
    :leave =>Data[0][2][:leave]}

#    emotion_str = 'Data[0][:£1] = {:enter=>{:max_counter=>60,:data =>[{:file=>"emotions",:rect=>[£3,£2,16,16],:zoom=>1,:position=>:center_pos, :oy_offset => 20},nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,{:rect=>[£4,£2,16,16]}],:loop => false},:stay => Data[0][:exclamation][:stay],:leave =>Data[0][2][:leave]}'
    emotion_str = 'Data[0][:£1] = {:enter=>{:max_counter=>60,:data =>[{:file=>"emotions",:rect=>[£3,£2,16,16],:zoom=>1,:position=>:center_pos, :oy_offset => 10},nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,{:rect=>[£4,£2,16,16]}],:loop => false},:stay => Data[0][:exclamation][:stay],:leave =>Data[0][2][:leave]}'
    module_eval(emotion_str.gsub('£1', 'poison').gsub!('£2', '0').gsub!('£3','32').gsub!('£4','48'))
    module_eval(emotion_str.gsub('£1', 'exclamation2').gsub!('£2', '16').gsub!('£3','0').gsub!('£4','16'))
    module_eval(emotion_str.gsub('£1', 'interrogation').gsub!('£2', '32').gsub!('£3','0').gsub!('£4','16'))
    module_eval(emotion_str.gsub('£1', 'music').gsub!('£2', '16').gsub!('£3','32').gsub!('£4','48'))
    module_eval(emotion_str.gsub('£1', 'love').gsub!('£2', '32').gsub!('£3','32').gsub!('£4','48'))
    module_eval(emotion_str.gsub('£1', 'joy').gsub!('£2', '0').gsub!('£3','64').gsub!('£4','80'))
    module_eval(emotion_str.gsub('£1', 'sad').gsub!('£2', '16').gsub!('£3','64').gsub!('£4','80'))
    module_eval(emotion_str.gsub('£1', 'happy').gsub!('£2', '32').gsub!('£3','64').gsub!('£4','80'))
    module_eval(emotion_str.gsub('£1', 'angry').gsub!('£2', '0').gsub!('£3','96').gsub!('£4','112'))
    module_eval(emotion_str.gsub('£1', 'sulk').gsub!('£2', '16').gsub!('£3','96').gsub!('£4','112'))
    module_eval(emotion_str.gsub('£1', 'nocomment').gsub!('£2', '32').gsub!('£3','96').gsub!('£4','112'))

    module_function
    # Init the particle display on a new viewport
    # @param viewport [Viewport]
    def init(viewport)
      dispose if @stack
      @clean_stack = false
      @stack = Array.new
      @viewport = viewport
      @on_teleportation = false
    end
    # Update of the particles & stack cleaning if requested
    def update
      return unless @stack
      #> La ligne suivante a été supprimée suite aux menus, il faudra vérifier si il n'y a aucun problème relatif avec les combats et autre.
      #return dispose if $scene.class != Scene_Map
      @stack.each do |i|
        i.update if i and !i.disposed
      end
      if @clean_stack
        @clean_stack=false
        @stack.each_index do |i|
          @stack[i]=nil if @stack[i].disposed
        end
        @stack.compact!
      end
    end
    # Request to clean the stack
    def clean_stack
      @clean_stack = true
    end
    # Add a particle to the stack
    # @param character [Game_Character] the character on which the particle displays
    # @param tag [Integer] the index of the particle in the particle data
    def add_particle(character,tag)
      return unless @stack
      if a=Data[$game_variables[Var::PAR_DatID]]
        if a=a[tag]
          @stack.push(Particle_Object.new(character,a,@on_teleportation)) if character.character_name and character.character_name.size>0
        end
      end
    end
    # Add a parallax
    # @param image [String] name of the image in Graphics/Pictures/
    # @param x [Integer] x coordinate of the parallax from the first pixel of the Map (16x16 tiles /!\)
    # @param y [Integer] y coordinate of the parallax from the first pixel of the Map (16x16 tiles /!\)
    # @param z [Integer] z superiority in the tile viewport
    # @param zoom_x [Numeric] zoom_x of the parallax
    # @param zoom_y [Numeric] zoom_y of the parallax
    # @param opacity [Integer] opacity of the parallax (0~255)
    # @param blend_type [Integer] blend_type of the parallax (0, 1, 2)
    # @return [Parallax_Object]
    def add_parallax(image, x, y, z, zoom_x = 1, zoom_y = 1, opacity = 255, blend_type = 0)
      object = Parallax_Object.new(image, x, y, z, zoom_x, zoom_y, opacity, blend_type)
      @stack << object
      return object
    end
    # Add a building
    # @param image [String] name of the image in Graphics/Autotiles/
    # @param x [Integer] x coordinate of the building
    # @param y [Integer] y coordinate of the building
    # @param oy [Integer] offset y coordinate of the building in native resolution pixel
    # @param visible_from1 [Symbol, false] data parameter (unused there)
    # @param visible_from2 [Symbol, false] data parameter (unused there)
    # @return [Building_Object]
    def add_building(image, x, y, oy = 0, visible_from1 = false, visible_from2 = false)
      object = Building_Object.new(image, x, y, oy)
      @stack << object
      return object
    end
    # Return the viewport of in which the Particles are shown
    def viewport
      @viewport
    end
    # Tell the particle manager the game is warping the player. Particle will skip the :enter phase.
    # @param v [Boolean]
    def set_on_teleportation(v)
      @on_teleportation = v
    end
    # Dispose each particle
    def dispose
      return unless @stack
      t = Time.new
      @stack.each do |i|
        i.dispose if i and !i.disposed
      end
      @stack=nil
      #GC.start #> Supprimé pour cause de perte de temps
    end
  end
  # The object that describe a particle
  # @author Nuri Yuri
  class Particle_Object
    # The Zoom Division info
    ZoomDiv = Sprite_Character::ZoomDiv
    # if the particle is disposed
    # @return [Boolean]
    attr_reader :disposed
    # Create a particle object
    # @param character [Game_Character] the character on which the particle displays
    # @param data [Hash{Symbol => Hash}] the data of the particle
    #    field of the data hash :
    #       enter: the particle animation when character enter on the tile
    #       stay: the particle animation when character stay on the tile
    #       leave: the particle animation when character leave the tile
    #    field of the particle animation
    #       max_counter: the number of frame on the animation
    #       loop: Boolean # if the animation loops or not
    #       data: an Array of animation instructions (Hash)
    #    field of an animation instruction
    #       state: Symbol # the new state of the particle
    #       zoom: Numeric # the zoom of the particle
    #       position: Symbol # the position type of the particle (:center_pos, :character_pos)
    #       file: String # the filename of the particle in Graphics/Particles/
    #       angle: Numeric # the angle of the particle
    #       add_z: Integer # The z offset relatively to the character
    #       oy_offset: Integer # The offset in oy
    #       opacity: Integer # The opacity of the particle
    #       chara: Boolean # If the particle Bitmap is treaten like the Character bitmap
    #       rect: Array(Integer, Integer, Integer, Integer) # the parameter of the #set function of Rect (src_rect)
    # @param on_tp [Boolean] tells the particle to skip the :enter animation or not
    def initialize(character,data,on_tp=false)
      @x=character.x
      @y=character.y
      @character=character
      @map_id=$game_map.map_id
      @sprite=::Sprite.new(Particles.viewport)
      @data=data
      @counter=0
      @position_type=:center_pos
      @state=(on_tp ? :stay : :enter)
      @zoom = (zoom = ::Config::Specific_Zoom) ? zoom : ZoomDiv[1]#$zoom_factor.to_i]
      @add_z=@zoom
      @ox=0
      @oy=0
      @oy_off=0
    end
    # Update the particle animation
    def update
      return if @disposed
      return dispose if $game_map.map_id != @map_id
      data=@data[@state]
      if @counter<data[:max_counter]
        exectute_action(data[:data][@counter]) if data[:data][@counter]
        @counter+=1
      elsif @state==:enter
        @state=:stay
        @counter=0
      elsif @state==:stay 
        if (@x!=@character.x or @y!=@character.y)# or !@character.character_name or @character.character_name.size==0)
          @state=:leave
          @counter=0
        else
          @counter=0
        end
      elsif !data[:loop]
        dispose
        Particles.clean_stack
        return
      else
        @counter=0
      end
      update_sprite_position
    end
    # Execute an animation instruction
    # @param action [Hash] the animation instruction
    def exectute_action(action)
      if d=action[:state]
        @state = d
      end
      if d=action[:zoom]
        @sprite.zoom=d*1#$zoom_factor
      end
      if d=action[:file] #Choix d'un fichier
        @sprite.bitmap=RPG::Cache.particle(d)#Bitmap.new("Graphics/Particles/#{d}")
        @ox = (@sprite.bitmap.width*@sprite.zoom_x)/2
        @oy = (@sprite.bitmap.height*@sprite.zoom_y)/2
      end
      if d=action[:position]
        @position_type=d
      end
      if d=action[:angle]
        @sprite.angle=d
      end
      if d=action[:add_z]
        @add_z=d
      end
      if d=action[:oy_offset]
        @oy_off=d
      end
      if d=action[:opacity]
        @sprite.opacity=d
      end
      #DOIS ETRE A LA FIN !
      if d=action[:chara]
        cw=@sprite.bitmap.width/4
        ch=@sprite.bitmap.height/4
        sx = @character.pattern * cw
        sy = (@character.direction - 2) / 2 * ch
        @sprite.src_rect.set(sx,sy,cw,ch)
        @ox=(cw*@sprite.zoom_x)/2
        @oy=(ch*@sprite.zoom_y)/2
      end
      if d=action[:rect] #choix d'un src_rect
        @sprite.src_rect.set(*d)
        @ox = (d[2]*@sprite.zoom_x)/2
        @oy = (d[3]*@sprite.zoom_y)/2
      end
    end
    # Update the position of the particle sprite
    def update_sprite_position
      case @position_type
      when :center_pos
        @sprite.x=((@x*128 - $game_map.display_x + 3) / 4 + 32)/@zoom
        @sprite.y=((@y*128 - $game_map.display_y + 5) / 4 + 32)
        @sprite.z=@character.screen_z(0)/@zoom
        if @sprite.y>=@character.screen_y
          @sprite.z=(@character.screen_z(0)+@add_z)#/@zoom
        else
          @sprite.z=(@character.screen_z(0)-1)#/@zoom
        end
        @sprite.y/=@zoom
        @sprite.ox=@ox * @zoom
        @sprite.oy=@oy * @zoom + @oy_off#(@oy+@oy_off)*@zoom
      when :character_pos
        @sprite.x=@character.screen_x/@zoom
        @sprite.y=@character.screen_y/@zoom
        @sprite.z=(@character.screen_z(0)+@add_z)/@zoom
        @sprite.ox=@ox
        @sprite.oy=@oy+@oy_off
      end
    end
    # Dispose the particle
    def dispose
      return if @disposed
      @sprite.dispose unless @sprite.disposed?
      @sprite = nil
      @disposed = true
    end
  end
  # Object that describe a parallax as a particle
  # @author Nuri Yuri
  class Parallax_Object
    # If the parallax is disposed
    # @return [Boolean]
    attr_reader :disposed
    # The parallax sprite
    # @return [Sprite]
    attr_accessor :sprite
    # the factor that creates an automatic offset in x
    # @return [Numeric]
    attr_accessor :factor_x
    # the factor that creates an automatic offset in y
    # @return [Numeric]
    attr_accessor :factor_y
    # Creates a new Parallax_Object
    # @param image [String] name of the image in Graphics/Pictures/
    # @param x [Integer] x coordinate of the parallax from the first pixel of the Map (16x16 tiles /!\)
    # @param y [Integer] y coordinate of the parallax from the first pixel of the Map (16x16 tiles /!\)
    # @param z [Integer] z superiority in the tile viewport
    # @param zoom_x [Numeric] zoom_x of the parallax
    # @param zoom_y [Numeric] zoom_y of the parallax
    # @param opacity [Integer] opacity of the parallax (0~255)
    # @param blend_type [Integer] blend_type of the parallax (0, 1, 2)
    def initialize(image, x, y, z, zoom_x = 1, zoom_y = 1, opacity = 255, blend_type = 0)
      @sprite = ::Sprite.new(Particles.viewport, true)
      @sprite.z = z
      @sprite.zoom_x = zoom_x
      @sprite.zoom_y = zoom_y
      @sprite.opacity = opacity
      @sprite.blend_type = blend_type
      @sprite.bitmap = ::RPG::Cache.picture(image)
      @x = x + MapLinker::OffsetX * 16
      @y = y + MapLinker::OffsetY * 16
      @factor_x = 0
      @factor_y = 0
      update
    end
    # Update the parallax position
    def update
      dx = $game_map.display_x / 8
      dy = $game_map.display_y / 8
      @sprite.x = (@x - dx) + (@factor_x * dx)
      @sprite.y = (@y - dy) + (@factor_y * dy)
    end
    # Dispose the parallax
    def dispose
      return if @disposed
      @sprite.dispose unless @sprite.disposed?
      @sprite = nil
      @disposed = true
    end
  end
  # Object that describe a building on the Map as a Particle
  # @author Nuri Yuri
  class Building_Object
    # If the building is disposed
    # @return [Boolean]
    attr_reader :disposed
    # The building sprite
    # @return [Sprite]
    attr_accessor :sprite
    # Create a new Building_Object
    # @param image [String] name of the image in Graphics/Autotiles/
    # @param x [Integer] x coordinate of the building
    # @param y [Integer] y coordinate of the building
    # @param oy [Integer] offset y coordinate of the building in native resolution pixel
    def initialize(image, x, y, oy)
      @sprite = ::Sprite.new(Particles.viewport, true)
      @sprite.bitmap = ::RPG::Cache.autotile(image)
      @sprite.oy = @sprite.bitmap.height - oy - 16
      @x = (x + MapLinker::OffsetX) * 16
      @y = (y + MapLinker::OffsetY) * 16
      @real_y = (y + MapLinker::OffsetY) * 128
      update
    end
    # Update the building position (x, y, z)
    def update
      dx = $game_map.display_x / 8
      dy = $game_map.display_y / 8
      @sprite.x = (@x - dx)
      @sprite.y = (@y - dy)
      @sprite.z = (@real_y - $game_map.display_y + 4) / 4 + 94 #< C'est optimisé au poil de couille, le tilemap est un peu chiant ^^'
    end
    # Dispose the building
    def dispose
      return if @disposed
      @sprite.dispose unless @sprite.disposed?
      @sprite = nil
      @disposed = true
    end
  end
end
