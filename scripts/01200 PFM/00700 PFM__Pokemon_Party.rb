module PFM
  # The game informations and Party management
  #
  # The global object is stored in $pokemon_party
  # @author Nuri Yuri
  class Pokemon_Party
    include GameData::PokemonParty
    # The Pokemon of the Player
    # @return [Array<PFM::Pokemon>]
    attr_accessor :actors
    # The Pokedex of the player
    # @return [PFM::Pokedex]
    attr_accessor :pokedex
    # The bag of the player
    # @return [PFM::Bag]
    attr_accessor :bag
    # The informations about the player and the game
    # @return [PFM::Trainer]
    attr_accessor :trainer
    # The PC storage of the player
    # @return [PFM::Storage]
    attr_accessor :storage
    # The environment informations
    # @return [PFM::Environnement]
    attr_accessor :env
    # The informations about the Wild Pokemon Battle
    # @return [PFM::Wild_Battle]
    attr_accessor :wild_battle
    # The number of steps the repel will work
    # @return [Integer]
    attr_accessor :repel_count
    # The number of steps the player did
    # @return [Integer]
    attr_accessor :steps
    # The daycare management object
    # @return [PFM::Daycare]
    attr_accessor :daycare
    # The in game berry data
    # @return [Hash]
    attr_accessor :berries
    # The player quests informations
    # @return [PFM::Quests]
    attr_accessor :quests
    # The game options
    # @return [PFM::Options]
    attr_accessor :options
    # The list of Pokemon imported from Pokemon Gemme 3.9
    # @return [Array<PFM::Pokemon>]
    attr_accessor :pokemon_39
    # The $game_variables
    # @return [Game_Variables]
    attr_accessor :game_variables
    # The $game_switches
    # @return [Game_Switches]
    attr_accessor :game_switches
    # The $game_self_switches
    # @return [Game_SelfSwitches]
    attr_accessor :game_self_switches
    # The $game_self_variables
    # @return [Game_SelfVariables]
    attr_accessor :game_self_variables
    # The $game_system
    # @return [Game_System]
    attr_accessor :game_system
    # The $game_screen
    # @return [Game_Screen]
    attr_accessor :game_screen
    # The $game_actors
    # @return [Game_Actors]
    attr_accessor :game_actors
    # The $game_party
    # @return [Game_Party]
    attr_accessor :game_party
    # The $game_map
    # @return [Game_Map]
    attr_accessor :game_map
    # The $game_player
    # @return [Game_Player]
    attr_accessor :game_player
    # The $game_temp
    # @return [Game_Temp]
    attr_accessor :game_temp
    # Create a new Pokemon Party
    # @param battle [Boolean] if its a party of a NPC battler
    # @param starting_language [String] the lang id of the game described by this object
    def initialize(battle = false, starting_language = 'fr')
      @actors = []
      @bag = PFM::Bag.new
      @repel_count = 0
      @steps = 0
      return if battle
      game_state_initialize(starting_language)
      rmxp_boot unless $tester
    end

    private

    # Initialize the game state variable
    # @param starting_language [String] the lang id of the game described by this object
    def game_state_initialize(starting_language)
      @game_variables = Game_Variables.new
      @game_switches = Game_Switches.new
      $game_switches ||= @game_switches
      @game_self_switches = Game_SelfSwitches.new
      @game_self_variables = Game_SelfVariables.new
      @game_temp = Game_Temp.new
      @game_system = Game_System.new
      @game_screen = Game_Screen.new
      @game_actors = Game_Actors.new
      @game_party = Game_Party.new
      @game_troop = Game_Troop.new
      @game_map = Game_Map.new
      @game_player = Game_Player.new
      expand_global_var
      @pokedex = PFM::Pokedex.new
      @trainer = PFM::Trainer.new
      @options = PFM::Options.new(starting_language)
      load_parameters
      @storage = PFM::Storage.new
      @env = PFM::Environnement.new
      @wild_battle = PFM::Wild_Battle.new
      @daycare = PFM::Daycare.new
      @berries = {}
      @quests = PFM::Quests.new
    end

    # Perform the RMXP bootup
    def rmxp_boot
      expand_global_var # Safety to be sure the variable are really ok
      @game_party.setup_starting_members
      log_info("$data_system.start_map_id = #{$data_system.start_map_id}")
      log_info("$data_system.start_x = #{$data_system.start_x}")
      log_info("$data_system.start_x = #{$data_system.start_y}")
      @game_map.setup($data_system.start_map_id)
      @game_player.moveto($data_system.start_x + Yuki::MapLinker.get_OffsetX, $data_system.start_y + Yuki::MapLinker.get_OffsetY)
      @game_player.refresh
      @game_map.autoplay
      ## @game_map.update
    end

    public

    # Expand the global variable with the instance variables of the object
    def expand_global_var
      $pokemon_party = self
      $game_variables = @game_variables
      $game_switches = @game_switches
      $game_self_switches = @game_self_switches
      $game_temp = @game_temp
      $game_system = @game_system
      $game_screen = @game_screen
      $game_actors = @game_actors
      $game_party = @game_party
      $game_troop = @game_troop
      $game_map = @game_map
      $game_player = @game_player
      #Accès rapide des variables de $pokemon_party
      $actors = @actors
      $pokedex = @pokedex
      $trainer = @trainer
      $options = @options
      $bag = @bag
      $storage = @storage
      $env = @env
      $wild_battle = @wild_battle
      # Patch 2016-02-12
      @daycare ||= PFM::Daycare.new
      $daycare = @daycare
      # Patch 2017-05-08
      @quests ||= PFM::Quests.new
      $quests = @quests
      # Patch 2017-06-10
      @game_self_variables ||= Game_SelfVariables.new
      $game_self_variables = @game_self_variables
      # Force the pokemon selection to be unset.
      $game_variables[Yuki::Var::Party_Menu_Sel] = -1
    end
    # Increase the @step and manage events that trigger each steps
    # @return [Array] informations about events that has been triggered.
    def increase_steps
      @steps+=1
      return_data=[]
      #>Déclanchement des combats
      encounter_step = $game_map.encounter_step
      ability = $actors[0] ? $actors[0].ability_db_symbol : :__undef__
      if IncFreqEnc.include?(ability)
        encounter_step *= 1.5
      elsif DecFreqEnc.include?(ability) ||
            (HailDecreasingFreqEnc.include?(ability) && $env.hail?) || # > Rideau Neige
            (SandstormDecreasingFreqEnc.include?(ability) && $env.sandstorm?) # > Voile Sable
        encounter_step *= 0.5
      end
      if !$game_system.encounter_disabled && (@repel_count <= 0) && ((@steps % encounter_step) == 0) &&
         @wild_battle.available?
        $game_system.map_interpreter.launch_common_event(1) unless $game_system.map_interpreter.running?
      end
      #>Gestion de la repousse
      if @repel_count > 0
        @repel_count -= 1
        return_data << [:repel_check] if @repel_count == 0
      end
      #>Gérer la pension
      @daycare.update
      #>Gestion des oeufs & poison
      psn = false
      psn_check = ((@steps - (@steps / 8) * 8) == 0)
      loyal_check = ((@steps - (@steps / 512) * 512) == 0)
      # ArmureMagma / corps ardent : Eclosion plus rapide
      amca = HatchSpeedIncreasingAbilities.include?(ability)
      @actors.each do |i|
        if i
          # Oeuf
          if i.step_remaining > 0
            i.step_remaining -= 1
            i.step_remaining -= 1 if amca && (i.step_remaining > 0)
            if i.step_remaining == 0
              i.egg_finish
              return_data << [:egg, i]
            end
          elsif i.hp > 0
            # Poison
            if psn_check
              if i.poisoned?
                unless psn
                  return_data << [:psn]
                  psn = true
                end
                i.hp -= 1
              elsif i.toxic?
                unless psn
                  return_data << [:psn]
                  psn = true
                end
                i.hp -= 2
              end
              if i.hp <= 1
                i.hp = 1
                i.cure
                return_data << [:psn_end, i]
              end
            end
            # Loyalty
            i.loyalty += 1 if loyal_check
          end
        end
      end
      return return_data
    end
    # Change the repel_count
    # @param v [Integer]
    def set_repel_count(v)
      @repel_count=v.to_i.abs
    end
    # Return the repel_count
    # @return [Integer]
    def get_repel_count
      return @repel_count
    end
    # Return the money the player has
    # @return [Integer]
    def money
      return $game_party.gold
    end
    # Change the money the player has
    # @param v [Integer]
    def money=(v)
      $game_party.gold = v.to_i
    end
    # Add money
    # @param n [Integer] amount of money to add
    def add_money(n)
      return lose_money(-n) if n < 0
      $game_party.gold+=n
    end
    # Lose money
    # @param n [Integer] amount of money to lose
    def lose_money(n)
      return add_money(-n) if n < 0
      $game_party.gold-=n
      $game_party.gold=0 if($game_party.gold<0)
    end
    # Load some parameters (audio volume & text)
    def load_parameters
      Audio.music_volume = @options.music_volume
      Audio.sfx_volume = @options.sfx_volume
      GameData::Text.load
    end
  end
end
