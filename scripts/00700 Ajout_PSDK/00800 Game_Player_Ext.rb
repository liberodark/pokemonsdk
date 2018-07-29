#encoding: utf-8

class Game_Player
  # Move or turn the player according to its input. The common event 2 can be triggered there
  # @author Nuri Yuri
  def player_update_move
    #mouse_input = Input.kpress?(1)
    #> Système permettant au héros de tourner sur lui même
    @wturn = 10 - @move_speed if @lastdir4 == 0 and !(Input.repeat?(:UP) or Input.repeat?(:DOWN) or 
    Input.repeat?(:LEFT) or Input.repeat?(:RIGHT))

    @lastdir4 = Input.dir4 #(mouse_input ? mouse_dir4 : Input.dir4)
    swamp_detect = (@in_swamp and @in_swamp > 4)
    if bool = ((@wturn > 0) | swamp_detect)
      player_turn(swamp_detect)
    else
      player_move
    end
    # _BUMP v2
    unless moving?
      unless $game_temp.common_event_id != 0 or @surfing or @sliding
        if @last_x == @x and @last_y == @y
          if @lastdir4 != 0 and !bool
            @step_anime = true
            if (@old_pattern == 3 and @pattern == 0) or (@old_pattern == 1 and @pattern == 2)
              Audio.se_play(BUMP_FILE)
            end
          else
            @step_anime = false
          end
        else
          @last_x = @x
          @last_y = @y
        end
      else
        if @surfing
          if @last_x == @x and @last_y == @y
            if @lastdir4 != 0 and !bool
              if (@old_pattern == 3 and @pattern == 0) or (@old_pattern == 1 and @pattern == 2)
                Audio.se_play(BUMP_FILE)
              end
            end
          else
            @last_x = @x
            @last_y = @y
          end
        end
      end
    else
      @step_anime = false unless @surfing
    end
    @old_pattern = @pattern
    #_BUMP
    #Lignes pour faire le bump à la Pokémon, faut les conserver !!!
=begin
    if(@bump_count>0)
      @bump_count -= 1
      unless @surfing or @sliding
        if @on_acro_bike or $game_switches[::Yuki::Sw::EV_Bicycle]
          @step_anime = false
        else
          @step_anime = !(@bump_count==0 or @lastdir4==0)
        end
        if @step_anime
          if (@old_pattern == 0 and @pattern == 1) or (@old_pattern == 2 and @pattern == 3)
            Audio.se_play(BUMP_FILE)
          end
        end
        @old_pattern = @pattern
      end
    end
=end
    #Gestion de la course + vélo course
    if @on_acro_bike
      if !@acro_appearence and Input.press?(:B)
        @acro_appearence = true
        $game_temp.common_event_id = 2 #> Appel de l'apparence du héros
      elsif @acro_appearence and !Input.press?(:B)
        @acro_appearence = false
        $game_temp.common_event_id = 2 #> Appel de l'apparence du héros
      end
    else
      unless @surfing
        #> Faire courir le héros
        if !bool and @lastdir4 != 0 and $game_switches[::Yuki::Sw::EV_CanRun] and 
          !$game_switches[::Yuki::Sw::EV_Run] and Input.press?(:B) and
          !@step_anime # Test avec bump
          $game_switches[::Yuki::Sw::EV_Run] = true
          $game_temp.common_event_id = 2 #> Appel de l'apparence du héros
        #> Arrêt course
        elsif (@lastdir4 == 0 or !Input.press?(:B) or $game_system.map_interpreter.running? or @step_anime) and $game_switches[::Yuki::Sw::EV_Run]
          $game_switches[::Yuki::Sw::EV_Run] = false
          $game_temp.common_event_id = 2 #> Appel de l'apparence du héros
        end
      end
    end
  end
  # Turn the player on himself. Does some calibration for the Acro Bike.
  # @author Nuri Yuri
  def player_turn(swamp_detect)
    if swamp_detect and @lastdir4 != @direction and @lastdir4 != 0
      @in_swamp -= 1
    end
    last_dir = @direction
    case @lastdir4
    when 2
      turn_down
    when 4
      turn_left
    when 6
      turn_right
    when 8
      turn_up
    else
      if system_tag == Hole
        $game_temp.common_event_id = 8 #> Appel de l'évènement de gestion de la chute
      elsif @on_acro_bike and Input.press?(:B)
        jump(0, 0) if update_acro_bike(20, system_tag)
      end
    end
    calibrate_acro_direction(last_dir)
  end
  # Move the player. Does some calibration for the Acro Bike.
  # @author Nuri Yuri
  def player_move
    #> gestion du vélo cross
    jumping = false
    if @on_acro_bike and Input.press?(:B)
      return if (jumping = update_acro_bike(10, front_system_tag)) == false
    end
    last_dir = @direction
    #> Gestion du déplacement
    case @lastdir4
    when 2
      jumping ? jump(0, 1) : move_down
    when 4
      turn_left
      jumping ? jump(-1, 0) : move_left
    when 6
      turn_right
      jumping ? jump(1, 0) : move_right
    when 8
      jumping ? jump(0, -1) : move_up
    #else
      #@cant_bump=true
    end
    calibrate_acro_direction(last_dir)
    #> Gestion du sol cracké
    if (sys_tag = system_tag) == CrackedSoil
      $game_map.data[@x, @y, 0] = $game_map.data[@x, @y, 0] + 1
      if @move_speed < 5
        $game_temp.common_event_id = 8 #> Appel de l'évènement de gestion de la chute
      end
    elsif sys_tag == Hole
      $game_temp.common_event_id = 8 #> Appel de l'évènement de gestion de la chute
    end
  end
  # Reset the direction of the player when he's on bike bridge 
  # @author Nuri Yuri
  def calibrate_acro_direction(last_dir)
    if @__bridge and sys_tag = @__bridge.first
      return if sys_tag != AcroBikeRL and sys_tag != AcroBikeUD
    end
    case @direction
    when 8, 2
      @direction = last_dir if sys_tag == AcroBikeRL
    when 4, 6
      @direction = last_dir if sys_tag == AcroBikeUD
    end
  end
  # Update the Acro Bike jump info
  # @author Nuri Yuri
  def update_acro_bike(count, sys_tag)
    if SlideTags.include?(sys_tag) or sys_tag == MachBike
      return nil
    end
    if @wturn == 0 and !$game_map.jump_passable?(@x, @y, @lastdir4)
      return nil if system_tag != AcroBike and !@__bridge
    end
    if @acro_count < count
      @acro_count += 1
      return false
    end
    @acro_count = 0
    return true
  end
  # Tags that are Bike bridge (jumpable on Acro Bike)
  AccroTag = [AcroBikeRL, AcroBikeUD]
  # Test if the player can pass Bike bridge
  # @author Nuri Yuri
  def acro_passable_check(d, result)
    on_bike = (@on_acro_bike or $game_switches[::Yuki::Sw::EV_Bicycle])
    if @z > 1 and on_bike
      sys_tag = front_system_tag
      case d
      when 4, 6
        return true if sys_tag == AcroBikeRL
      when 8, 2
        return true if sys_tag == AcroBikeUD
      else
        return true if sys_tag == AcroBikeUD or sys_tag == AcroBikeRL
      end
      return false if @__bridge and AccroTag.include?(@__bridge.first) and !ZTag.include?(sys_tag)
      @__bridge = nil if result and ZTag.include?(sys_tag)
    elsif on_bike
      sys_tag = front_system_tag
      return false if sys_tag == SwampBorder or sys_tag == DeepSwamp
    end
    return result
  end
  #> Same as Game_Character but with Acro bike
  # @author Nuri Yuri
  def bridge_down_check(z)
    if z > 1 and !@__bridge
      if (sys_tag = front_system_tag) == BridgeUD or 
          (sys_tag == AcroBikeUD and (@on_acro_bike or $game_switches[::Yuki::Sw::EV_Bicycle]))
       @__bridge = [sys_tag, system_tag]
      end
    elsif z > 1 and @__bridge
      @__bridge = nil if @__bridge.last == system_tag and front_system_tag != @__bridge.first
    end
  end
  alias bridge_up_check bridge_down_check
  #> Same as Game_Character but with Acro bike
  # @author Nuri Yuri
  def bridge_left_check(z)
    if z > 1 and !@__bridge
      if (sys_tag = front_system_tag) == BridgeRL or 
          (sys_tag == AcroBikeRL and (@on_acro_bike or $game_switches[::Yuki::Sw::EV_Bicycle]))
        @__bridge = [sys_tag, system_tag]
      end
    elsif z > 1 and @__bridge
      @__bridge = nil if @__bridge.last == system_tag and front_system_tag != @__bridge.first
    end
  end
  alias bridge_right_check bridge_left_check
=begin
  def turn_down
    if @z > 1 and (@on_acro_bike or $game_switches[::Yuki::Sw::EV_Bicycle])
      return false if system_tag == AcroBikeRL
    end
    super
  end

  def turn_up
    if @z > 1 and (@on_acro_bike or $game_switches[::Yuki::Sw::EV_Bicycle])
      return false if system_tag == AcroBikeRL
    end
    super
  end

  def turn_left
    if @z > 1 and (@on_acro_bike or $game_switches[::Yuki::Sw::EV_Bicycle])
      return false if system_tag == AcroBikeUD
    end
    super
  end

  def turn_right
    if @z > 1 and (@on_acro_bike or $game_switches[::Yuki::Sw::EV_Bicycle])
      return false if system_tag == AcroBikeUD
    end
    super
  end
=end
=begin
  def mouse_dir4
    sx = Graphics.width / 2
    sy = Graphics.height / 2 #> /!\ PSDK DS => / 4
    mx = Input.mx
    my = Input.my
    px = mx - sx
    py = my - sy
    px2 = px.abs
    py2 = py.abs
    return 0 if(px2 <= 32 and py2 <= 32)
    if px < 0 #LEFT
      return ((py < 0) ? 8 : 2) if py2 > px2
      return 4
    else # Droite
      return ((py < 0) ? 8 : 2) if py2 > px2
      return 6
    end

  end
=end
  # Redefine of the update_move with the auto warp from the Yuki::MapLinker
  def update_move
    super()
    Yuki::MapLinker.test_warp unless moving?
  end
  # Define Acro Bike state of the Game_Player
  # @author Nuri Yuri
  def set_on_acro_bike(state)
    @on_acro_bike = state
    @acro_count = 0
  end
  # Search an invisible item
  def search_item
    $game_map.events.each do |event_id, event|
      if event.objetInvisible
        dx = (event.x - @x).abs
        dy = (event.y - @y).abs
        if dx <= 10 and dy <= 7
          Audio.se_play("Audio/SE/Nintendo")
          $game_player = event
          turn_toward_player
          $game_player = self
          return true
        end
      end
    end
    return false
  end
=begin
  if false #> Déplacement 8 directions
    alias base_update update
    def update
      unless moving? or $game_system.map_interpreter.running? or
             @move_route_forcing or $game_temp.message_window_showing or @sliding
        dir8  = Input.dir8
        case dir8
        when 9
          move_upper_right
        when 7
          move_upper_left
        when 1
          move_lower_left
        when 3
          move_lower_right
        end
      end
      base_update
    end
  end
=end
end
