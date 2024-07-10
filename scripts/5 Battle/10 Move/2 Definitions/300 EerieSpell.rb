module Battle
  class Move
    class EerieSpell < Basic
      # Test if the effect is working
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      # @return [Boolean]
      def effect_working?(user, actual_targets)
        return actual_targets.all? { |target| target.move_history.any? && target.skills_set[find_last_skill_position(target)]&.pp != 0 }
      end

      private

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        actual_targets.each do |target|
          last_skill = find_last_skill_position(target)
          next if target.move_history.empty? || target.skills_set[last_skill].pp == 0

          num = 3.clamp(1, target.skills_set[last_skill].pp)
          target.skills_set[last_skill].pp -= num
          scene.display_message_and_wait(parse_text_with_pokemon(19, 641, target, PFM::Text::MOVE[1] => target.skills_set[last_skill].name, '[VAR NUM1(0002)]' => num.to_s))
        end
      end

      # Find the last skill used position in the moveset of the Pokemon
      # @param pokemon [PFM::PokemonBattler]
      # @return [Integer]
      def find_last_skill_position(pokemon)
        pokemon.skills_set.each_with_index do |skill, i|
          return i if skill && skill.id == pokemon.move_history.last.move.id
        end

        return 0
      end
    end
    Move.register(:s_eerie_spell, EerieSpell)
  end
end