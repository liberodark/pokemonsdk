module GamePlay
  # Class that describes the functionment of the scene
  class MiningGame < BaseCleanUpdate::FrameBalanced
    # Constant that stock the Database of the Mining Game
    DATA = GameData::MiningGame::DATA_ITEM
    # The base music of the scene
    DEFAULT_MUSIC = 'audio/bgm/mining_game'
    # The number of tiles per lines in the table
    NB_X_TILES = 16
    # The number of tiles per columns in the table
    NB_Y_TILES = 13
    # The initial coordinates of the cursor used when in keyboard mode
    INITIAL_CURSOR_COORDINATES = [NB_X_TILES / 2, NB_Y_TILES / 2]
    # IDs of the text displayed when playing for the first time
    FIRST_TIME_TEXT = [[9005, 6], [9005, 7], [9005, 8], [9005, 10], [9005, 11], [9005, 12]]
    # IDs of the text displayed when playing for the first time (dynamite mode)
    FIRST_TIME_TEXT_ALTERNATIVE = [9005, 9]
    # List of the usable tools
    TOOLS = %i[pickaxe mace dynamite]
    # Pathname of the SE folder
    SE_PATH = 'audio/se/mining_game'
    # @return [UI::MiningGame::Tiles_Stack]
    attr_accessor :tiles_stack
    # @return [Array<PFM::MiningGame::Diggable>]
    attr_accessor :arr_items_won

    # Initialize the UI
    # @overload initialize(item_count, music_filename = DEFAULT_MUSIC)
    #   @param item_count [Integer, nil] the number of items to search (nil for random between 2 and 5)
    #   @param music_filename [String] the filename of the music to play
    #   @param grid_handler [PFM::MiningGame::GridHandler, nil] hand-chosen grid handler
    # @overload initialize(wanted_item_db_symbols, music_filename = DEFAULT_MUSIC)
    #   @param wanted_item_db_symbols [Array<Symbol>] the array containing the specific items (comprised between 1 and 5 items)
    #   @param music_filename [String] the filename of the music to play
    #   @param grid_handler [PFM::MiningGame::GridHandler, nil] hand-chosen grid handler
    def initialize(param = nil, music_filename = DEFAULT_MUSIC, grid_handler: nil)
      super()
      PFM.game_state.mining_game.nb_game_launched += 1
      @handler = grid_handler
      @handler ||= PFM::MiningGame::GridHandler.new(param.is_a?(Array) ? param : nil, param.is_a?(Integer) ? param : nil, NB_X_TILES, NB_Y_TILES)
      @current_tool = :pickaxe
      @controller = :mouse
      @last_tile_hit = INITIAL_CURSOR_COORDINATES.dup
      @arr_items_won = []
      # @type [Yuki::Animation::TimedAnimation]
      @animation = nil
      # @type [Yuki::Animation::TimedAnimation]
      @transition_animation = nil
      # States are :playing, :animation
      @ui_state = :playing
      @mbf_type = :mining_game
      @saved_grid_debug = false
      Audio.bgm_play(music_filename)
      @running = true
    end

    private

    # Save the current instance of the Mining Game in a file
    def save_instance_for_debug
      @saved_grid_debug = true
      Yuki::EXC.mining_game_reproduction(@handler)
    end
  end
end
