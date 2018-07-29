#encoding: utf-8

# Interpreter of the event script commands
class Interpreter < Interpreter_RMXP
  # Detect if the event can spot the player and move to the player
  # @param nb_pas [Integer] number of step the event should do to spot the player
  # @return [Boolean] if the event spot the player or not
  # @author Nuri Yuri
  def player_spotted?(nb_pas) #, self_calling = false)
    c = $game_map.events[@event_id]
    return false if (c.x-$game_player.x).abs > nb_pas or (c.y-$game_player.y).abs > nb_pas
    return false if c.z != $game_player.z #> Décommenter si pb avec ponts
    x = c.x
    y = c.y
    d = c.direction
    new_x = (d == 6 ? 1 : d == 4 ? -1 : 0)
    new_y = (d == 2 ? 1 : d == 8 ? -1 : 0)
    result = false
    #> Détection en face de l'évent
    result = true if $game_player.x == (x+new_x) and $game_player.y == (y+new_y)
    #> Détection en avançant (si non detecté avant)
    unless result
      0.upto(nb_pas) do |i|
        if(c.passable?(x, y, d, true))
          break(result = true) if $game_player.x == x and $game_player.y == y
        else
          result = true if $game_player.x == x and $game_player.y == y
          break
        end
        x+=new_x
        y+=new_y
      end
    end
    #> Détection d'une action volontaire du héros
    result ||= (Input.trigger?(:A) and $game_player.front_tile_event == c)
    #> Suppression du mode course sur le héros
    if result
      $game_switches[::Yuki::Sw::EV_Run] = false
      $game_temp.common_event_id = 2
    end
    return result  
  end

  alias trainer_spotted player_spotted?
  # Detect the player in a specific direction
  # @param nb_pas [Integer] the number of step between the event and the player
  # @param direction [Symbol, Integer] the direction : :right, 6, :down, 2, :left, 4, :up or 8
  # @return [Boolean]
  # @author Nuri Yuri
  def detect_player(nb_pas, direction)
    c = $game_map.events[@event_id]
    dx = $game_player.x - c.x
    dy = $game_player.y - c.y
    case direction
    when :right, 6
      return (dy == 0 and dx >= 0 and dx <= nb_pas)
    when :down, 2
      return (dx == 0 and dy >= 0 and dy <= nb_pas)
    when :left, 4
      return (dy == 0 and dx <= 0 and dx >= -nb_pas)
    else
      return (dx == 0 and dy <= 0 and dy >= -nb_pas)
    end
  end
  # Detect the player in a rectangle around the event
  # @param nx [Integer] the x distance of detection between the event and the player
  # @param ny [Integer] the y distance of detection between the event and the player
  # @return [Boolean]
  # @author Nuri Yuri
  def detect_player_rect(nx, ny)
    c = $game_map.events[@event_id]
    dx = ($game_player.x - c.x).abs
    dy = ($game_player.y - c.y).abs
    return (dx <= nx and dy <= ny)
  end
  # Detect the player in a circle around the event
  # @param r [Numeric] the square radius (r = R²) of the circle around the event
  # @return [Boolean]
  # @author Nuri Yuri
  def detect_player_circle(r)
    r *= r
    c = $game_map.events[@event_id]
    dx = $game_player.x - c.x
    dy = $game_player.y - c.y
    return ((dx * dx) + (dy * dy)) <= r
  end
  # Change the tileset
  # @param filename [String] filename of the new tileset
  def change_tileset(filename)
    $scene.change_tileset(filename)
  end
  # Delete the current event forever
  def delete_this_event_forever
    $env.set_event_delete_state(@event_id)
    $game_map.events[@event_id].erase
  end
end
