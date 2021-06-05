module Battle
  class Move
    private

    # Target item reducing move type power
    TYPE_RESISTING_BERRY = {}
    # Mod3 calculation
    # @param user [PFM::PokemonBattler] user of the move
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_mod3(user, target)
      # Mod3 = SRF * EB * TL * TRB
      result = 1
      # Effects
      logic.each_effects(user, target) do |e|
        result *= e.mod3_multiplier(user, target, self)
      end
      if super_effective?
        # EB
        result *= 1.2 if user.hold_item?(:expert_belt)
      end
      # TRB
      return result * calc_trb(target)
    end

    # TRB calculation
    # @param target [PFM::PokemonBattler] target of the move
    # @return [Numeric]
    def calc_trb(target)
      # @type [Hash]
      trb = TYPE_RESISTING_BERRY[target.battle_item_db_symbol]
      return 1 unless trb

      effectiveness_method = trb[:effectiveness_method]
      # TODO: Add berry consumed & hook
      return VAL_0_5 if (!effectiveness_method || send(effectiveness_method)) && type == trb[:type]

      return 1
    end

    class << self
      # Define a berry that gives resistance to the Pokemon holding it depending on the move type & effectiveness
      # @param db_symbol [Symbol] symbol of the berry in the database
      # @param type [Integer] type of the move
      # @param effectiveness [Integer] 0 = not very effective, 1 = just normal, 2 = super effective
      def define_type_resisting_berry(db_symbol, type, effectiveness = 2)
        if effectiveness == 0
          effectiveness_method = :not_very_effective?
        elsif effectiveness == 2
          effectiveness_method = :super_effective?
        else
          effectiveness_method = nil
        end
        TYPE_RESISTING_BERRY[db_symbol] = { type: type, effectiveness_method: effectiveness_method }
      end
    end

    define_type_resisting_berry(:occa_berry, GameData::Types::FIRE)
    define_type_resisting_berry(:passho_berry, GameData::Types::WATER)
    define_type_resisting_berry(:wacan_berry, GameData::Types::ELECTRIC)
    define_type_resisting_berry(:rindo_berry, GameData::Types::GRASS)
    define_type_resisting_berry(:yache_berry, GameData::Types::ICE)
    define_type_resisting_berry(:chople_berry, GameData::Types::FIGHTING)
    define_type_resisting_berry(:kebia_berry, GameData::Types::POISON)
    define_type_resisting_berry(:shuca_berry, GameData::Types::GROUND)
    define_type_resisting_berry(:coba_berry, GameData::Types::FLYING)
    define_type_resisting_berry(:payapa_berry, GameData::Types::PSYCHIC)
    define_type_resisting_berry(:tanga_berry, GameData::Types::BUG)
    define_type_resisting_berry(:charti_berry, GameData::Types::ROCK)
    define_type_resisting_berry(:kasib_berry, GameData::Types::GHOST)
    define_type_resisting_berry(:haban_berry, GameData::Types::DRAGON)
    define_type_resisting_berry(:colbur_berry, GameData::Types::DARK)
    define_type_resisting_berry(:babiri_berry, GameData::Types::STEEL)
    define_type_resisting_berry(:chilan_berry, GameData::Types::NORMAL, 1)
    define_type_resisting_berry(:roseli_berry, GameData::Types::FAIRY)
  end
end
