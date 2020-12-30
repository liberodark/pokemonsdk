module BattleUI
  # UI element showing the exp distribution
  class ExpDistribution < UI::SpriteStack
    include UI

    # Create a new exp distribution
    # @param viewport [Viewport]
    # @param scene [Battle::Scene]
    # @param exp_data [Hash{ PFM::PokemonBattler => Integer }] info about experience each pokemon should receive
    def initialize(viewport, scene, exp_data)
      super(viewport)
      @scene = scene
      @pokemon = find_expable_pokemon
      @exp_data = exp_data.dup
      @done = false
      create_sprites
    end

    def update
      if @statistics
        update_statistics
      else
        @animation.update
      end
      @bars.each(&:update)
    end

    def done?
      return @done
    end

    def start_animation
      animations = @exp_data.map do |pokemon, exp|
        create_exp_animation_for(pokemon, exp)
      end.compact
      return if (@done = animations.empty?)

      # @type [Yuki::Animation::TimedAnimation]
      @animation = Yuki::Animation.se_play('exp_sound')
      animations.each { |(animation, _)| @animation.parallel_add(animation) }
      @animation.play_before(Yuki::Animation.send_command_to(Audio, :se_stop))
      animations.each do |(_, pokemon)|
        @animation.play_before(Yuki::Animation.send_command_to(self, :show_level_up, pokemon)) if pokemon
        index = @pokemon.index(pokemon)
        @bars[index].leveling_up = true if index
      end
      @animation.play_before(Yuki::Animation.send_command_to(self, :start_animation))
      @animation.start
    end

    private

    def update_statistics
      return if $game_temp.message_window_showing
      return unless Input.trigger?(:A)

      @statistics.dispose
      @statistics = nil
    end

    def create_sprites
      # @type [Array<PokemonInfo>]
      @bars = @pokemon.map.with_index do |pokemon, index|
        push_sprite(PokemonInfo.new(@viewport, index, pokemon, @exp_data[pokemon].to_i))
      end
    end

    # Get the list of Pokemon that can get exp (are from player party)
    # @return [Array<PFM::PokemonBattler>]
    def find_expable_pokemon
      return 2.times.map do |bank|
        6.times.map { |position| @scene.logic.battler(bank, position) }.compact.select(&:from_party?)
      end.flatten
    end

    # Function that shows level up of a Pokemon
    # @param pokemon [PFM::PokemonBattler]
    def show_level_up(pokemon)
      list = pokemon.level_up_stat_refresh
      @statistics = Statistics.new(@viewport, pokemon, list[0], list[1])
      index = @pokemon.index(pokemon)
      @bars[index].data = pokemon if index
      level_up_message(pokemon) if @exp_data[pokemon].to_i == 0 || pokemon.can_learn_skill_at_this_level?
    end

    # Show the level up message
    # @param receiver [PFM::PokemonBattler]
    # @param list [Array]
    def level_up_message(receiver)
      PFM::Text.set_num3(receiver.level.to_s, 1)
      Audio.me_play('audio/me/rosa_levelup')
      @scene.display_message(parse_text(18, 62, '[VAR 010C(0000)]' => receiver.given_name))
      PFM::Text.reset_variables
      receiver.check_skill_and_learn
      @scene.logic.evolve_request << receiver unless @scene.logic.evolve_request.include?(receiver)
    end

    # Function that create an exp animation for a specific pokemon
    # @param pokemon [PFM::PokemonBattler]
    # @param exp [Integer] total exp he should receive
    # @return [Array(Yuki::Animation::TimedAnimation, PFM::PokemonBattler), nil]
    def create_exp_animation_for(pokemon, exp)
      return nil if exp <= 0

      target_exp = pokemon.exp + exp
      next_exp_value = pokemon.exp_lvl.clamp(0, target_exp)
      @exp_data[pokemon] -= next_exp_value

      # actually create the animation
      original_exp = pokemon.exp
      exp_rate = pokemon.exp_rate
      pokemon.exp = next_exp_value
      time_to_process = ((pokemon.exp_rate - exp_rate) * 2).clamp(0, (next_exp_value - original_exp).abs / 60.0)
      animation = Yuki::Animation::DiscreetAnimation.new(time_to_process, pokemon, :exp=, original_exp, next_exp_value)
      return [animation, pokemon.exp == pokemon.exp_lvl ? pokemon : nil]
    end

    # UI element showing the basic information
    class PokemonInfo < UI::SpriteStack
      # The information of the Exp Bar
      EXP_BAR_INFO = [88, 2, 0, 0, 1]
      # Tell if the pokemon is leveling up or not
      # @return [Boolean]
      attr_reader :leveling_up
      # Coordinate where the UI element is supposed to show
      COORDINATES = [[17, 10], [162, 20], [17, 50], [162, 60], [17, 90], [162, 100]]
      # Create a new Pokemon Info
      # @param viewport [Viewport]
      # @param index [Integer]
      # @param pokemon [PFM::PokemonBattler]
      # @param exp_received [Integer]
      def initialize(viewport, index, pokemon, exp_received)
        super(viewport, *COORDINATES[index])
        @exp_received = exp_received
        @leveling_up = false
        create_sprites
        create_animation
        self.data = pokemon
      end

      # Update the animation
      def update
        @animation.update
        @exp_bar.data = @pokemon
      end

      # Set the data shown by the UI element
      # @param pokemon [PFM::PokemonBattler]
      def data=(pokemon)
        @pokemon = pokemon
        super(pokemon)
        @gender.x = 42 + @name.real_width
        @level_up_arrow.visible = leveling_up
      end

      # Set if the Pokemon is leveling up or not
      # @param leveling_up [Boolean]
      def leveling_up=(leveling_up)
        @leveling_up = leveling_up
        self.data = @pokemon
      end

      private

      def create_sprites
        @background = add_background('expbar')
        @name = add_text(37, 5, 0, 16, :given_name, color: 10, type: UI::SymText)
        @gender = add_sprite(5, 6, NO_INITIAL_IMAGE, type: UI::GenderSprite)
        @level = add_text(37, 20, 0, 13, :level_text2, color: 10, type: UI::SymText)
        @exp_obtained = add_text(116, 20, 0, 13, "+#{@exp_received}", 2, color: 10) if @exp_received > 0
        create_exp_bar
        @level_up_arrow = add_sprite(124, 7, 'battle/exp_level_up', 3, 1, type: SpriteSheet)
        @pokemon_icon = add_sprite(1, 2, NO_INITIAL_IMAGE, type: UI::PokemonIconSprite)
      end

      def create_exp_bar
        @exp_bar = push_sprite UI::Bar.new(@viewport, @x + 37, @y + 29, RPG::Cache.interface('battle/bars_exp'), *EXP_BAR_INFO)
        @exp_bar.data_source = :exp_rate
      end

      def create_animation
        animation = Yuki::Animation::TimedLoopAnimation.new(0.5)
        animation.play_before(Yuki::Animation::DiscreetAnimation.new(0.5, @level_up_arrow, :sx=, 0, 2))
        animation.start
        @animation = animation
      end
    end

    # UI element showing the new statistics
    class Statistics < UI::SpriteStack
      # Create a new Statistics UI
      # @param viewport [Viewport]
      # @param pokemon [PFM::Pokemon] Pokemon that is currently leveling up
      # @param list0 [Array<Integer>] old basis stats
      # @param list1 [Array<Integer>] new basis stats
      def initialize(viewport, pokemon, list0, list1)
        super(viewport, 0, 144)
        @list0 = list0
        @list1 = list1
        create_sprites
        self.data = pokemon
      end

      private

      def create_sprites
        @background = add_background('battle/exp_stats_bar')
        @name = add_text(160, 11, 0, 16, :given_name, 1, color: 0, type: UI::SymText)
        @gender = add_sprite(220, 11, NO_INITIAL_IMAGE, type: UI::GenderSprite)
        create_stats_texts
      end

      # Create all the stats texts
      def create_stats_texts
        6.times do |i|
          ox = 156 * (i / 3)
          oy = 19 * (i % 3)
          add_text(13 + ox, 33 + oy, 0, 16, text_get(22, 121 + i), color: 10)
          add_text(130 + ox, 33 + oy, 0, 16, @list1[i].to_s, 2, color: 0)
          add_text(139 + ox, 33 + oy, 0, 16, "+#{@list1[i] - @list0[i]}", color: 16)
        end
      end
    end
  end
end
