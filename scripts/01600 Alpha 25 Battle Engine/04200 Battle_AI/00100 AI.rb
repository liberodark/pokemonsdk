module Battle
  class AI
    # Create a new Logic instance
    # @param battle_scene [Scene] scene that hold the logic object
    def initialize(battle_scene)
      @battle_scene = battle_scene
    end

    # Trigger the AI work
    # @return [Array<Hash>] the action to do
    def trigger
      actions = PFM::IA.start
      return translate_actions(actions)
    end

    private

    # Translate .24 message into .25 messages
    # @param actions [Array<Array>]
    # @return [Array<Hash>]
    def translate_actions(actions)
      return actions.map do |action|
        case action.first
        when 0 # Attack
          next translate_attack(*action)
        when 1 # Item
          next translate_item(*action)
        when 2 # Switch
          next translate_switch(*action)
        else
          next translate_flee(*action)
        end
      end
    end

    # Translate an attack action to a Hash
    # @param type [Integer]
    # @param skill_index [Integer]
    # @param target [Array<PFM::PokemonBattler24>]
    # @param launcher [PFM::PokemonBattler24]
    # @return [Hash]
    def translate_attack(type, skill_index, target, launcher)
      if target.is_a?(Integer)
        target_position24 = target
      elsif target.first.position < 0 && target[1]
        target_position24 = target[1].position
      else
        target_position24 = target.first.position
      end
      target_bank = target_position24 < 0 ? 1 : 0
      target_position = target_position24 < 0 ? -target_position24 - 1 : target_position24
      return {
        type: :attack,
        skill: launcher.skills_set[skill_index],
        target_bank: target_bank,
        target_position: target_position,
        launcher: launcher.pokemon_battler
      }
    end

    # Translate item
    # @param type [Integer]
    # @param id [Integer]
    # @param extend_data [Object]
    # @param position [Integer]
    def translate_item(type, (id, extend_data, position))
      bank = position < 0 ? 1 : 0
      position = position < 0 ? -position - 1 : position
      target = @battle_scene.logic.battler(bank, position)
      bag = @battle_scene.logic.bags[bank].first
      return {
        type: :item,
        item_id: id,
        bag: bag,
        target: target
      }
    end

    # Translate switch
    # @param type [Integer]
    # @param new_index [Integer]
    # @param index [Integer]
    def translate_switch(type, new_index, index)
      position1 = index < 0 ? -index - 1 : index
      position2 = new_index < 0 ? -new_index - 1 : new_index
      return {
        type: :switch,
        who: @battle_scene.logic.battler(1, position1),
        with: @battle_scene.logic.battler(1, position2)
      }
    end

    # Translate flee
    def translate_flee(type, pokemon, reason)
      return {
        type: :flee,
        target: pokemon,
        reason: reason
      }
    end
  end
end
