#encoding: utf-8

module Yuki
  # The Player Follower Manager
  # @author Nuri Yuri
  module FollowMe
    #>Les deux constantes suivantes définissent le chara utilisé pour le follow_Me.
    #Dans mon dossier characters, ils sont fait de la sorte :
    #001_0.png Bulbizarre forme 0
    #001s_0.png Bulbizarre forme 0 shiny
    #201_4.png Zarbi E (les formes commencent à 0 :p)
    @followers = []
    module_function
    # Init the FollowMe on a new viewport. Previous Follower are disposed.
    # @param viewport [Viewport] the new viewport
    def init(viewport)
      dispose if(@followers)
      @viewport = viewport
      @followers = Array.new
    end
    # Update of the Follower Management. Their graphics are updated here.
    def update
      #===
      #>Verification de la commutation du switch d'activation
      #ça provoque la suppression des follower si false
      #===
      if(@laststate != $game_switches[Sw::FM_Enabled])
        @laststate=$game_switches[Sw::FM_Enabled]
        unless(@laststate)
          @followers.each do |i|
            next unless i
            i.dispose
          end
          @followers.clear
        end
      end
      #Retour si le système est inactif
      return unless $game_switches[Sw::FM_Enabled]
      chara_update = ($game_variables[Var::FM_Sel_Foll] == 0)
      #>Variable indiquant le dernier follower
      last_follower = $game_player
      #>Index de parcourt des followers
      i = 0
      #>Index de parcourt d'une entité
      j = 0
      #>Gestion des humains
      0.upto($game_variables[Var::FM_N_Human]-1) do |j|
        if($game_actors[i+2])
          last_follower = update_follower(last_follower, i, $game_actors[j+2], chara_update)
          i += 1
        end
      end
      #>Gestion des Pokémon du joueur
      0.upto($game_variables[Var::FM_N_Pokem]-1) do |j|
        if($actors[j] and !$actors[j].dead?)
          last_follower = update_follower(last_follower, i, $actors[j], chara_update)
          i += 1
        end
      end
      #>Gestion des Pokémon de l'ami
      other_party = $storage.other_party
      0.upto($game_variables[Var::FM_N_Friend]-1) do |j|
        if(other_party[j] and !other_party[j].dead?)
          last_follower = update_follower(last_follower, i, other_party[j], chara_update)
          i += 1
        end
      end
      #>Suppression des followers restant
      while @followers.size > i
        @followers.pop.dispose
      end
      return
    end
    # Update of a single follower
    # @param last_follower [Game_Character] the last follower (in case of Follower creation)
    # @param i [Integer] index in the @followers Array
    # @param entity [PFM::Pokemon, Game_Actor] the entity that is shown as a follower
    # @param chara_update [Boolean] if the character graphics and informations needs to be updated
    # @return [Game_Character] the character that will become the last_follower
    def update_follower(last_follower, i, entity, chara_update)
      follower = @followers[i]
      unless follower
        follower = Sprite_Character.new(@viewport, Game_Character.new)
        position_character(follower.character, i)
        follower.character.z = $game_player.z
      end
      character = follower.character
      last_follower.set_follower(character)
      if(chara_update)
        character.character_name = entity.character_name
        character.is_pokemon = character.step_anime = entity.class == PFM::Pokemon
      end
      character.move_speed = $game_player.move_speed
      character.through = true
      character.update
      follower.update
      follower.z -= 1 if character.x == $game_player.x and character.y == $game_player.y
      return (@followers[i] = follower).character
    end
    # Sets the default position of a follower
    # @param c [Game_Character] the character
    # @param i [Integer] the index of the caracter in the @followers Array
    def position_character(c,i)
      return if $game_variables[Yuki::Var::FM_Sel_Foll]>0
      c1=(i==0 ? $game_player : @followers[i-1].character)
      x=c1.x
      y=c1.y
      if $game_switches[Sw::Env_CanFly] or $game_switches[Sw::FM_NoReset]
        case c1.direction
        when 2
          y-=1
        when 4
          x+=1
        when 6
          x-=1
        else
          y+=1
        end
      end
      #===
      #Ici, j'ai mis c.passable? à cause du system tag, si ça plantouille
      #remplace le c.passable? par $game_map.passable?
      #===
      c.through=false
      if(c.passable?(x,y,0))#c1.direction)) #$game_map
        c.moveto(x,y)
      else
        c.moveto(c1.x,c1.y)
      end
      c.through=true
      c.direction=$game_player.direction
      c.update
    end
    # Clears the follower (and dispose them)
    def clear
      if(@followers)
        @followers.each do |i|
          i.dispose if i
        end
      end
      @followers.clear
    end
    # Retreive a follower
    # @param i [Integer] index of the follower in the @followers Array
    # @return [Game_Character] $game_player if i is invalid
    def get_follower(i)
      if(@followers and @followers[i])
        return @followers[i].character
      end
      return $game_player
    end
    # yield a block on each Followers
    # @param block [Proc] the block to call
    # @example Turn each follower down
    #   Yuki::FollowMe.each_follower { |c| c.turn_down }
    def each_follower(&block)
      @followers.collect{|c| c.character}.each(&block)
    end
    # Sets the position of each follower (Warp)
    # @param args [Array<Integer, Integer, Integer>] array of x, y, direction
    def set_positions(*args)
      width = $game_map.width - 1
      height = $game_map.height - 1
      x = y = 0
      (args.size/3).times do |i|
        next unless v=@followers[i]
        c=v.character
        x = args[i*3]
        y = args[i*3+1]
        x = width if x > width
        y = height if y > height
        x = 0 if x < 0
        y = 0 if y < 0
        c.moveto(x,y)
        c.direction=args[i*3+2]
        c.update
        c.particle_push
        v.update
      end
    end
    # Reset position of each follower to the player (entering in a building)
    def reset_position
      return unless @followers
      $game_player.reset_follower_move
      @followers.size.times do |i|
        v=@followers[i]
        c=v.character
        c.moveto($game_player.x,$game_player.y)
        c.direction=$game_player.direction
        c.instance_variable_set(:@memorized_move, nil)
        c.update
        v.update
        v.z-=1
      end
    end
    # Test if a character is a Follower of the player
    def is_player_follower?(c)
      return unless @followers
      return @followers.include?(c)
    end
    # Set the Follower Manager in Battle mode. When getting out of battle every character will get its particle pushed.
    def set_battle_entry(v = true)
      @was_fighting = v
    end
    # Push particle of each character if the Follower Manager was in Battle mode.
    def particle_push
      if(@was_fighting)
        each_follower { |c| c.particle_push }
      end
      @was_fighting = false
    end
    # Dispose the follower and release resources.
    def dispose
      if(@followers)
        @followers.each do |i|
          i.dispose if i and !i.disposed?
        end
      end
      @followers = nil
      @viewport = nil
    end
  end
end
