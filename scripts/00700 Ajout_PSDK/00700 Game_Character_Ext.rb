#encoding: utf-8

class Game_Character
  # Return tile position in front of the player
  # @return [Array(Integer, Integer)] the position x and y
  def front_tile
    xf = @x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
    yf = @y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
    return [xf, yf]
  end
  # Return the event that stand in the front of the Player
  # @return [Game_Event, nil]
  def front_tile_event
    xf = @x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
    yf = @y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
    $game_map.events.each_value do |event|
      return event if event.x == xf and event.y == yf
    end
    return nil
  end
  # Check a the #front_event has a specific name
  # @return [Boolean]
  # @author Nuri Yuri
  def front_name_check(name)
    v = self.front_tile_event
    return true if v and v.event.name == name
    return false
  end
  alias front_name_detect front_name_check
  # Return the id of the #front_tile_event
  # @return [Integer, 0] 0 if no front_tile_event
  # @author Nuri Yuri
  def front_tile_id
    v = self.front_tile_event
    return v.event.id if v
    return 0
  end
  # Remove the memorized moves of the follower
  # @author Nuri Yuri
  def reset_follower_move
    if @memorized_move
      @memorized_move_arg = @memorized_move = nil
    end
    @follower.reset_follower_move if @follower
  end
  # Move a follower
  # @author Nuri Yuri
  def follower_move
    return unless @follower
    return if $game_variables[Yuki::Var::FM_Sel_Foll]>0 #>Pour la mise en scène
    if @memorized_move
      @memorized_move_arg ? @follower.send(@memorized_move,*@memorized_move_arg) : @follower.send(@memorized_move)
      @memorized_move_arg=nil
      @memorized_move=nil
      return
    #elsif @follower.sliding? and @follower.system_tag != TIce
    #  return
    end
    x=@x-@follower.x
    y=@y-@follower.y
    d=@direction
    d2=@follower.direction
    case d
    when 2 #bas
      if x<0
        @follower.move_left
      elsif x>0
        @follower.move_right
      elsif y>1
        @follower.move_down
      elsif y==0# and d2==8
        @follower.move_up
      end
    when 4 #gauche
      if y<0
        @follower.move_up
      elsif y>0
        @follower.move_down
      elsif x<-1
        @follower.move_left
      elsif x==0# and d2==6
        @follower.move_right
      end
    when 6 #droite
      if y<0
        @follower.move_up
      elsif y>0
        @follower.move_down
      elsif x>1
        @follower.move_right
      elsif x==0# and d2==4
        @follower.move_left
      end
    when 8  #haut
      if x<0
        @follower.move_left
      elsif x>0
        @follower.move_right
      elsif y<-1
        @follower.move_up
      elsif y==0# and d2==2
        @follower.move_down
      end
    end
  end
  # Warp the follower to the event it follows
  # @author Nuri Yuri
  def move_follower_to_character
    return unless @follower
    return if $game_variables[Yuki::Var::FM_Sel_Foll]>0 #>Pour la mise en scène
    @follower.x = @x
    @follower.y = @y
  end
  # Check if the follower slides
  # @return [Boolean]
  # @author Nuri Yuri
  def follower_sliding?
    if @follower
      return @follower.follower_sliding? unless @follower.sliding?
      return true
    end
    return false
  end
  # Define the function check_event_trigger_touch to prevent bugs
  def check_event_trigger_touch(*args) 

  end
  # Define the follower of the event
  # @param follower [Game_Character, Game_Event] the follower
  # @author Nuri Yuri
  def set_follower(follower)
    @follower = follower
  end
  # Push a particle to the particle stack if possible
  # @author Nuri Yuri
  def particle_push
    case system_tag
    when TGrass
      Yuki::Particles.add_particle(self,1)
    when TTallGrass
      Yuki::Particles.add_particle(self,2)
    end
  end
  # Return the SystemTag where the Game_Character stands
  # @return [Integer] ID of the SystemTag
  # @author Nuri Yuri
  def system_tag
    return $game_map.system_tag(@x,@y)
  end
  # Return the SystemTag in the front of the Game_Character
  # @return [Integer] ID of the SystemTag
  # @author Nuri Yuri
  def front_system_tag
    xf = @x + (@direction == 6 ? 1 : @direction == 4 ? -1 : 0)
    yf = @y + (@direction == 2 ? 1 : @direction == 8 ? -1 : 0)
    return $game_map.system_tag(xf,yf)
  end
  # Set the Game_Character in the "surfing" mode (not able to walk on ground but able to walk on water)
  # @author Nuri Yuri
  def set_surfing
    @surfing = true
  end
  # Check if the Game_Character is in the "surfing" mode
  # @return [Boolean]
  # @author Nuri Yuri
  def surfing?
    return @surfing
  end
  # Check if the Game_Character slides
  # @return [Boolean]
  # @author Nuri Yuri
  def sliding?
    return @sliding
  end
  # Look directly to a specific event
  # @param event_id [Integer] id of the event on the Map
  # @author Nuri Yuri
  def look_to(event_id)
    return unless event = $game_map.events[event_id]
    delta_x = event.x - @x
    delta_y = event.y - @y
    if delta_x.abs <= delta_y.abs
      if delta_y < 0
        self.turn_up
      else
        self.turn_down
      end
    else
      if delta_x < 0
        self.turn_left
      else
        self.turn_right
      end
    end
  end
  # Adjust the Character informations related to the brige when it moves down (or up)
  # @param z [Integer] the z position
  # @author Nuri Yuri
  def bridge_down_check(z)
    if z > 1 and !@__bridge
      if (sys_tag = front_system_tag) == BridgeUD
        @__bridge = [sys_tag, system_tag]
      end
    elsif z > 1 and @__bridge
       @__bridge = nil if @__bridge.last == system_tag
    end
  end
  alias bridge_up_check bridge_down_check
  # Adjust the Character informations related to the brige when it moves left (or right)
  # @param z [Integer] the z position
  # @author Nuri Yuri
  def bridge_left_check(z)
    if z > 1 and !@__bridge
      if (sys_tag = front_system_tag) == BridgeRL
        @__bridge = [sys_tag, system_tag]
      end
    elsif z > 1 and @__bridge
      @__bridge = nil if @__bridge.last == system_tag
    end
  end
  alias bridge_right_check bridge_left_check
  # Check bridge information and adjust the z position of the Game_Character
  # @param sys_tag [Integer] the SystemTag
  # @author Nuri Yuri
  def z_bridge_check(sys_tag)
    @z = ZTag.index(sys_tag) if ZTag.include?(sys_tag)
    @z = 1 if @z < 1
    @z = 0 if @z == 1 and (sys_tag == BridgeRL or sys_tag == BridgeUD)
    @__bridge = nil if @__bridge and @__bridge.last == sys_tag
  end
  # Array of SystemTag that define stairs
  StairsTag = [StairsL, StairsD, StairsU, StairsR]
  # Dynamic move_speed value of the Game_Character, return a different value than @move_speed
  # @return [Integer] the dynamic move_speed
  # @author Nuri Yuri
  def move_speed
    #> Pour les swamp
    if @in_swamp
      return @in_swamp == 1 ? 2 : 1
    end
    #> Patch des escaliers
    move_speed = @move_speed
    if move_speed > 1
      direction = @direction
      sys_tag = system_tag
      if (direction==6 and (sys_tag==StairsR or $game_map.system_tag(@x-1, @y)==StairsL)) or
                (direction==4 and (sys_tag==StairsL or $game_map.system_tag(@x+1, @y)==StairsR))
        move_speed -=1
      elsif (direction == 2 or direction==8) and (sys_tag == StairsU or sys_tag == StairsD)
        move_speed -=1
      end
    end
    return move_speed
  end
  # Check if it's possible to have contact interaction with this Game_Character at certain coordinates
  # @param x [Integer] x position
  # @param y [Integer] y position
  # @param z [Integer] z position
  # @return [Boolean]
  # @author Nuri Yuri
  def contact?(x, y, z)
    @x == x and y == @y and (@z - z).abs <= 1
  end
  # Detect if the event walks in a swamp or a deep swamp and change the Game_Character states.
  # @author Nuri Yuri
  def detect_swamp
    sys_tag = system_tag
    if sys_tag == SwampBorder
      @in_swamp = 1
    elsif sys_tag == DeepSwamp
      @in_swamp = 4 + (rand(2) == 0 ? 4 + rand(4) : 0)
    else
      @in_swamp = false
    end
  end
  # SystemTags that triggers "sliding" state
  SlideTags = [TIce, RapidsL, RapidsR, RapidsU, RapidsD]
  # End of the movement process
  # @param no_follower_move [Boolean] if the follower should not move
  # @author Nuri Yuri
  def movement_process_end(no_follower_move = false)
    follower_move unless no_follower_move
    particle_push
    @sliding = true if SlideTags.include?(sys_tag = system_tag) or sys_tag == MachBike
    z_bridge_check(sys_tag)
    detect_swamp
  end
  # Show an emotion to an event or the player
  # @param type [Symbol] the type of emotion (see wiki)
  # @param wait [Integer] the number of frame the event will wait after this command.
  def emotion(type, wait = 34)
    Yuki::Particles.add_particle(self, type)
    @wait_count = wait
  end
end
