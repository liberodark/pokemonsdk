module PFM
  class Pokemon
    # Learn a new skill
    # @param db_symbol [Symbol] db_symbol of the move in the database
    # @return [Boolean, nil] true = learnt, false = already learnt, nil = couldn't learn
    def learn_skill(db_symbol)
      move = data_move(db_symbol)
      return false if skill_learnt?(move.db_symbol, only_in_move_set: true)

      if @skills_set.size < 4
        @skills_set << PFM::Skill.new(move.db_symbol)
        @skill_learnt << move.db_symbol unless @skill_learnt.include?(move.id) || @skill_learnt.include?(move.db_symbol)
        form_calibrate if data.db_symbol == :keldeo
        return true
      end
      return nil
    end

    # Forget a skill by its id
    # @param db_symbol [Symbol] db_symbol of the move in the database
    # @param delete_from_learnt [Boolean] if the skill should be deleted from the skill_learnt attribute of the Pokemon
    def forget_skill(db_symbol, delete_from_learnt: false)
      move = data_move(db_symbol)
      @skills_set.delete_if { |skill| skill.db_symbol == move.db_symbol }
      @skill_learnt.delete_if { |skill_id| data_move(skill_id).db_symbol == move.db_symbol } if delete_from_learnt
      form_calibrate if data.db_symbol == :keldeo
    end

    # Swap the position of two skills in the skills_set
    # @param index1 [Integer] Index of the first skill to swap
    # @param index2 [Integer] Index of the second skill to swap
    def swap_skills_index(index1, index2)
      @skills_set[index1], @skills_set[index2] = @skills_set[index2], @skills_set[index1]
      @skills_set.compact!
    end

    # Replace the skill at a specific index
    # @param index [Integer] index of the skill to replace by a new skill
    # @param db_symbol [Symbol] db_symbol of the move in the database
    def replace_skill_index(index, db_symbol)
      return if index >= 4

      move = data_move(db_symbol)
      @skills_set[index] = PFM::Skill.new(move.db_symbol)
      @skills_set.compact!
      @skill_learnt << move.db_symbol unless @skill_learnt.include?(move.id) || @skill_learnt.include?(move.db_symbol)
      form_calibrate if data.db_symbol == :keldeo
    end

    # Has the pokemon already learnt a skill ?
    # @param db_symbol [Symbol] db_symbol of the move
    # @param only_in_move_set [Boolean] if the function only check in the current move set
    # @return [Boolean]
    def skill_learnt?(db_symbol, only_in_move_set: true)
      return false if egg?

      move = data_move(db_symbol)
      return true if @skills_set.any? { |skill| skill && skill.db_symbol == move.db_symbol }
      return false if only_in_move_set

      return @skill_learnt.include?(move.id) || @skill_learnt.include?(move.db_symbol)
    end
    alias has_skill? skill_learnt?

    # Find a skill in the moveset of the Pokemon
    # @param db_symbol [Symbol] db_symbol of the skill in the database
    # @return [PFM::Skill, false]
    def find_skill(db_symbol)
      return false if egg?

      move = data_move(db_symbol)
      @skills_set.each do |skill|
        return skill if skill && skill.db_symbol == move.db_symbol
      end
      return false
    end

    # Check if the Pokemon can learn a new skill and make it learn the skill
    # @param silent [Boolean] if the skill is automatically learnt or not (false = show skill learn interface & messages)
    # @param level [Integer] The level to check in order to learn the moves (<= 0 = evolution)
    def check_skill_and_learn(silent = false, level = @level)
      learn_move = proc do |db_symbol|
        next if skill_learnt?(db_symbol)
        next GamePlay.open_move_teaching(self, db_symbol) unless silent

        @skills_set << PFM::Skill.new(db_symbol)
        @skills_set.shift if @skills_set.size > 4
        @skill_learnt << db_symbol unless @skill_learnt.include?(id) || @skill_learnt.include?(db_symbol)
      end

      if level <= 0
        data.move_set.select(&:evolution_learnable?).each do |move|
          learn_move.call(move.move)
        end
      else
        data.move_set.select { |move| move.level_learnable? && move.level == level }.each do |move|
          learn_move.call(move.move)
        end
      end
    end

    # Can learn skill at this level
    # @param level [Integer]
    def can_learn_skill_at_this_level?(level = @level)
      data.move_set.select { |move| move.level_learnable? && move.level == level }.any?
    end

    # Check if the Pokemon can learn a skill
    # @param db_symbol [Integer, Symbol] id or db_symbol of the move
    # @return [Boolean, nil] nil = learnt, false = cannot learn, true = can learn
    def can_learn?(db_symbol)
      return false if egg?

      db_symbol = data_move(db_symbol).db_symbol if db_symbol.is_a?(Integer)
      return nil if skill_learnt?(db_symbol)

      return data.move_set.any? { |move| move.move == db_symbol && !move.breed_learnable? }
    end

    # Get the list of all the skill the Pokemon can learn again
    # @param mode [Integer] Define the moves that can be learnt again :
    #   1 = breed_moves + learnt + potentially_learnt
    #   2 = all moves
    #   other = learnt + potentially_learnt
    # @return [Array<Symbol>]
    def remindable_skills(mode = 0)
      move_set = data.move_set
      level = mode == 2 ? Float::INFINITY : @level

      moves = move_set.select { |move| move.level_learnable? && level >= move.level }.map(&:move)
      moves.concat(@skill_learnt.map { |move| move.is_a?(Integer) ? data_move(move).db_symbol : move })
      moves.concat(move_set.select { |move| move.breed_learnable? || move.evolution_learnable? }.map(&:move)) if mode == 1 || mode == 2

      return (moves - skills_set.map(&:db_symbol)).uniq
    end

    # Load the skill from an Array
    # @param skills [Array] the skills array (containing IDs or Symbols)
    def load_skill_from_array(skills)
      skills.each_with_index do |skill, j|
        next skills_set[j] = nil if skill == :__remove__
        next if skill == 0 || skill == :__undef__ || skill.is_a?(String)

        replace_skill_index(j, skill)
      end
      skills_set.compact!
    end

    # Compatibility for deprecated battle engine
    alias moveset skills_set
  end
end
