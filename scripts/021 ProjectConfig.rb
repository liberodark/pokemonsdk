module Configs
  # Module holding all the project config
  module Project
    # Device configuration
    class Devices
      # Is mouse disabled
      # @return [Boolean]
      attr_accessor :is_mouse_disabled

      # Skin of the mouse
      # @return [String]
      attr_accessor :mouse_skin
    end

    # Display configuration of the project
    class Display
      # Get the game resolution
      # @return [Point]
      attr_reader :game_resolution

      # Get the default window scale
      # @return [Integer]
      attr_accessor :window_scale

      # Is the game running in fullscreen
      # @return [Boolean]
      attr_accessor :is_fullscreen

      # Is the player always centered on the screen
      # @return [Boolean]
      attr_accessor :is_player_always_centered

      # Get the tilemap settings
      # @return [TilemapSettings]
      attr_reader :tilemap_settings

      # Data structure describing a point
      class Point
        # Get the x coodinate
        # @return [Integer]
        attr_reader :x

        # Get the y coordinate
        # @return [Integer]
        attr_reader :y

        def initialize(x, y)
          @x = x
          @y = y
        end
      end

      # Data class describing Tilemap configuration
      class TilemapSettings
        # Get the tilemap class
        # @return [String]
        attr_reader :tilemap_class

        # Get the size of the tilemap
        # @return [Point]
        attr_reader :tilemap_size

        # Get the number of frame autotiles does not animate
        # @return [Integer]
        attr_reader :autotile_idle_frame_count

        # Get the zoom of the tiles as character
        # @return [Float]
        attr_reader :character_tile_zoom

        # Get the zoom of the sprite as character
        # @return [Float]
        attr_reader :character_sprite_zoom

        # Get the center of the screen in sub pixel size
        # @return [Point]
        attr_reader :center

        # Get the map linker offset
        # @return [Point]
        attr_reader :map_linker_offset

        # Tell if the game uses the old map linker settings
        # @return [Boolean]
        attr_reader :uses_old_map_linker

        def initialize(v)
          @tilemap_class = v[:tilemapClass]
          @tilemap_size = Point.new(v[:tilemapSize][:x], v[:tilemapSize][:y])
          @autotile_idle_frame_count = v[:autotileIdleFrameCount]
          @character_tile_zoom = v[:characterTileZoom]
          @character_sprite_zoom = v[:characterSpriteZoom]
          @center = Point.new(v[:center][:x], v[:center][:y])
          @map_linker_offset = Point.new(v[:maplinkerOffset][:x], v[:maplinkerOffset][:y])
          @uses_old_map_linker = v[:isOldMaplinker]
        end
      end

      def game_resolution=(res)
        @game_resolution = Point.new(res[:x] || 320, res[:y] || 240)
      end

      def tilemap_settings=(v)
        @tilemap_settings = TilemapSettings.new(v)
      end
    end

    # Option configurations
    class GameOptions
      # Get the order of options
      # @return [Array<Symbol>]
      attr_reader :order

      def order=(v)
        @order = v.map(&:to_sym)
      end

      # Set the options of the game
      # @param v [nil]
      def options=(v)
        # 000
      end
    end

    # Text display configurations
    class Texts
      # Get the font config
      # @return [Font]
      attr_reader :fonts

      # Get the message config
      # @return [Hash<String => MessageConfig>]
      attr_reader :messages

      # Get the choice config
      # @return [Hash<String => ChoiceConfig>]
      attr_reader :choices

      def fonts=(v)
        @fonts = Font.new(v)
      end

      def messages=(v)
        @messages = v.map { |k, val| [k == :any ? :any : k.to_s, MessageConfig.new(val)] }.to_h
      end

      def choices=(v)
        @choices = v.map { |k, val| [k == :any ? :any : k.to_s, ChoiceConfig.new(val)] }.to_h
      end

      # Font configuration
      class Font
        # Is the game supporting the pokemon number feature
        # @return [Boolean]
        attr_reader :supports_pokemon_number

        # Get all the ttf files the game uses
        # @return [Array<Hash>]
        attr_reader :ttf_files

        # Get all the alt size the game uses
        # @return [Array<Hash>]
        attr_reader :alt_sizes

        def initialize(v)
          @supports_pokemon_number = v[:isSupportsPokemonNumber]
          @ttf_files = v[:ttfFiles]
          @alt_sizes = v[:altSizes]
        end
      end

      # Configuration of choice box
      class ChoiceConfig
        # Get the window skin
        # @return [String, nil]
        attr_reader :window_skin

        # Get the border spacing
        # @return [Integer]
        attr_reader :border_spacing

        # Get the default font
        # @return [Integer]
        attr_reader :default_font

        # Get the default color
        # @return [Integer]
        attr_reader :default_color

        # Get the color_mapping
        # @return [Hash{ Integer => Integer }]
        attr_reader :color_mapping

        def initialize(v)
          @window_skin = v[:windowSkin]
          @border_spacing = v[:borderSpacing]
          @default_font = v[:defaultFont]
          @default_color = v[:defaultColor]
          @color_mapping = v[:colorMapping].transform_keys { |k| k.to_s.to_i }
        end
      end

      # Configuration of messages boxes
      class MessageConfig < ChoiceConfig
        # Get the window skin of the name box
        # @return [String, nil]
        attr_reader :name_window_skin

        # Get the number of lines the message has
        # @return [Integer]
        attr_reader :line_count

        def initialize(v)
          super(v)
          @name_window_skin = v[:nameWindowSkin]
          @line_count = v[:lineCount]
        end
      end
    end

    # Generic settings
    class Settings
      # Get the maximum level
      # @return [Integer]
      attr_accessor :max_level

      # Tell if evolution always uses form 0 to fetch evolution data
      # @return [Boolean]
      attr_accessor :always_use_form0_for_evolution

      # Tell if we use form 0 of current creature when current form has no data
      # @return [Boolean]
      attr_accessor :use_form0_when_no_evolution_data

      # Tell how much quantity of an item can be stored in the bag
      # @return [Integer]
      attr_accessor :max_bag_item_count
    end

    # Graphic configuration of the game
    class Graphic
      # Tell if the textures should be smooth
      # @return [Boolean]
      attr_accessor :smooth_texture

      # Tell if the vsync should be enabled
      # @return [Boolean]
      attr_accessor :vsync_enabled
    end

    # Information about the game
    class Infos
      # Get the game title
      # @return [String]
      attr_accessor :game_title

      # Get the game version
      # @return [Integer]
      attr_accessor :game_version
    end

    # Language configuration
    class Language
      # Give the default language code
      # @return [String]
      attr_accessor :default_language_code

      # Get the list of language user can choose
      # @return [Array<String>]
      attr_accessor :choosable_language_code

      # Get the name of the languages
      # @return [Array<String>]
      attr_accessor :choosable_language_texts
    end
  end
  # @!method self.devices
  #   @return [Project::Devices]
  register(:devices, 'devices_config', :json, false, Project::Devices)
  # @!method self.display
  #   @return [Project::Display]
  register(:display, 'display_config', :json, false, Project::Display)
  # @!method self.game_options
  #   @return [Project::GameOptions]
  register(:game_options, 'game_options_config', :json, false, Project::GameOptions)
  # @!method self.texts
  #   @return [Project::Texts]
  register(:texts, 'texts_config', :json, false, Project::Texts)
  # @!method self.settings
  #   @return [Project::Settings]
  register(:settings, 'settings_config', :json, false, Project::Settings)
  # @!method self.graphic
  #   @return [Project::Graphic]
  register(:graphic, 'graphic_config', :json, false, Project::Graphic)
  # @!method self.infos
  #   @return [Project::Infos]
  register(:infos, 'infos_config', :json, false, Project::Infos)
  # @!method self.language
  #   @return [Project::Language]
  register(:language, 'language_config', :json, false, Project::Language)
end
