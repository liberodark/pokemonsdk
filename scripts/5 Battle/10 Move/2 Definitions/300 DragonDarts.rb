module Battle
  class Move
    class DragonDarts < Basic
      private

      # Create a new move
      # @param db_symbol [Symbol] db_symbol of the move in the database
      # @param pp [Integer] number of pp the move currently has
      # @param ppmax [Integer] maximum number of pp the move currently has
      # @param scene [Battle::Scene] current battle scene
      def initialize(db_symbol, pp, ppmax, scene)
        super
        @allies_targets = nil
        @all_targets = nil
      end

      # Internal procedure of the move
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      def proceed_internal(user, targets)
        actual_targets = determine_targets(user, targets)
        return user.add_move_to_history(self, targets) unless actual_targets

        post_accuracy_check_effects(user, actual_targets)

        post_accuracy_check_move(user, actual_targets)

        play_animation(user, targets)

        deal_damage(user, actual_targets) &&
          effect_working?(user, actual_targets) &&
          deal_status(user, actual_targets) &&
          deal_stats(user, actual_targets) &&
          deal_effect(user, actual_targets)

        user.add_move_to_history(self, actual_targets)
        user.add_successful_move_to_history(self, actual_targets)
        @scene.visual.set_info_state(:move_animation)
        @scene.visual.wait_for_animation
      end

      # Determine which targets the user will focus
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      # @return [Array<PFM::PokemonBattler>, nil]
      def determine_targets(user, targets)
        @allies_targets = nil

        original_targets = targets.first
        # @type [Array<PFM::PokemonBattler>]
        actual_targets = proceed_internal_precheck(user, targets)

        if $game_temp.vs_type == 1
          return actual_targets.empty? ? nil : actual_targets
        end

        return actual_targets if actual_targets && original_targets.bank == user.bank

        if actual_targets.nil? && original_targets.bank != user.bank
          return if original_targets.effects.has?(:center_of_attention)

          actual_targets = @logic.allies_of(original_targets, true)
          actual_targets = actual_targets.sample if actual_targets.length > 1
          actual_targets = proceed_internal_precheck(user, actual_targets)
          return actual_targets.nil? ? nil : actual_targets
        end

        unless original_targets.effects.has?(:center_of_attention)
          @allies_targets = @logic.allies_of(original_targets, true)
          @allies_targets = @allies_targets.sample if @allies_targets.length > 1
        end

        return actual_targets
      end

      # Function that deals the damage to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_damage(user, actual_targets)
        @user = user
        @actual_targets = actual_targets
        @nb_hit = 0
        @hit_amount = 2
        @all_targets = nil

        @all_targets = actual_targets unless actual_targets.nil?
        @all_targets += @allies_targets unless @allies_targets.nil?

        @hit_amount.times do |i|
          target = @all_targets[i % @all_targets.size]
          next false unless target.alive?
          next false if user.dead?

          if [target] == @allies_targets
            result = proceed_internal_precheck(user, [target])
            return if result.nil?
          end

          @nb_hit += 1
          play_animation(user, [target]) if @nb_hit > 1
          hp = damages(user, target)
          @logic.damage_handler.damage_change_with_process(hp, target, user, self) do
            if critical_hit?
              scene.display_message_and_wait(@all_targets.size == 1 ? parse_text(18, 84) : parse_text_with_pokemon(19, 384, target))
            elsif hp > 0 && @nb_hit == @hit_amount
              efficent_message(effectiveness, target)
            end
          end
          recoil(hp, user) if recoil?
        end
        @scene.display_message_and_wait(parse_text(18, 33, PFM::Text::NUMB[1] => @nb_hit.to_s))
        return false if user.dead?

        return true
      end

      # Check if this the last hit of the move
      # Don't call this method before deal_damage method call
      # @return [Boolean]
      def last_hit?
        return true if @user.dead?
        return true unless @all_targets.all?(&:alive?)

        return @hit_amount == @nb_hit
      end

      # Tells if the move hits multiple times
      # @return [Boolean]
      def multi_hit?
        return true
      end
    end
    Move.register(:s_dragon_darts, DragonDarts)
  end
end
