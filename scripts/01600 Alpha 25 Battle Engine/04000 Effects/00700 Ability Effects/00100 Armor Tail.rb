module Battle
  module Effects
    class Ability
      class ArmorTail < Ability
        # Create a new Armor Tail effect
        # @param logic [Battle::Logic]
        # @param target [PFM::PokemonBattler]
        # @param db_symbol [Symbol] db_symbol of the ability
        def initialize(logic, target, db_symbol)
          super
          @affect_allies = true
        end

        # Function called when we try to use a move as the user (returns :prevent if user fails)
        # @param user [PFM::PokemonBattler]
        # @param targets [Array<PFM::PokemonBattler>]
        # @param move [Battle::Move]
        # @return [:prevent, nil] :prevent if the move cannot continue
        def on_move_prevention_user(user, targets, move)
          return if user == @target || user.bank == @target.bank
          return unless move&.priority(user) > 7 && (move&.one_target? || move&.db_symbol == :perish_song)
          return unless user&.can_be_lowered_or_canceled?

          move.scene.visual.show_ability(@target)
          move.scene.visual.wait_for_animation
          move.scene.display_message_and_wait(parse_text_with_pokemon(19, 911, user, PFM::Text::MOVE[1] => move.name))

          return :prevent
        end
      end
      register(:armor_tail, ArmorTail)
    end
  end
end