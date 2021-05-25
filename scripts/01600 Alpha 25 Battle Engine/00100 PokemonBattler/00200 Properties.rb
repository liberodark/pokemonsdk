
module PFM
  # Class defining a Pokemon during a battle, it aim to copy its properties but also to have the methods related to the battle.
  class PokemonBattler < Pokemon
    
    # Return the battler's combat property
    # @return [Integer]
    def atk_basis
      return @battle_properties[:atk_basis] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def atk_basis=(value)
      @battle_properties[:atk_basis] = value
    end

    # Restore the battler's property original value
    def restore_atk_basis
      @battle_properties.remove(:atk_basis)
    end

    # Return the battler's combat property
    # @return [Integer]
    def ats_basis
      return @battle_properties[:ats_basis] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def ats_basis=(value)
      @battle_properties[:ats_basis] = value
    end

    # Restore the battler's property original value
    def restore_ats_basis
      @battle_properties.remove(:ats_basis)
    end

    # Return the battler's combat property
    # @return [Integer]
    def dfe_basis
      return @battle_properties[:dfe_basis] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def dfe_basis=(value)
      @battle_properties[:dfe_basis] = value
    end

    # Restore the battler's property original value
    def restore_dfe_basis
      @battle_properties.remove(:dfe_basis)
    end

    # Return the battler's combat property
    # @return [Integer]
    def dfs_basis
      return @battle_properties[:dfs_basis] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def dfs_basis=(value)
      @battle_properties[:dfs_basis] = value
    end

    # Restore the battler's property original value
    def restore_dfs_basis
      @battle_properties.remove(:dfs_basis)
    end

    # Return the battler's combat property
    # @return [Integer]
    def spd_basis
      return @battle_properties[:spd_basis] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def spd_basis=(value)
      @battle_properties[:spd_basis] = value
    end

    # Restore the battler's property original value
    def restore_spd_basis
      @battle_properties.remove(:spd_basis)
    end

    # Return the battler's combat property
    # @return [Array<Integer>]
    def nature_id
      return @battle_properties[:nature_id] || super
    end

    # Set the battler's combat property
    # @param value [Array<Integer>]
    def nature_id=(value)
      return log_error("Wrong nature id : #{value}") unless GameData::Natures.id_valid?(value)

      @battle_properties[:nature_id] = value
    end

    # Restore the battler's property original value
    def restore_nature_id
      @battle_properties.remove(:nature_id)
    end

    # Return the battler's combat property
    # @return [Integer]
    def ability
      return @battle_properties[:ability] || super
    end

    # Set the battler's combat property
    # @param value [Array<Integer>]
    def ability=(value)
      return log_error("Wrong ability id : #{value}") unless GameData::Abilities.id_valid?(value)

      @battle_properties[:ability] = value
    end

    # Restore the battler's property original value
    def restore_ability
      @battle_properties.remove(:ability)
    end

    # Return the battler's combat property
    # @return [Integer]
    def height
      return @battle_properties[:height] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def height=(value)
      @battle_properties[:height] = value
    end

    # Restore the battler's property original value
    def restore_height
      @battle_properties.remove(:height)
    end

    # Return the battler's combat property
    # @return [Integer]
    def weight
      return @battle_properties[:weight] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def weight=(value)
      @battle_properties[:weight] = value
    end

    # Restore the battler's property original value
    def restore_weight
      @battle_properties.remove(:weight)
    end

    # Return the battler's combat property
    # @return [Integer]
    def gender
      return @battle_properties[:gender] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def gender=(value)
      if primary_data.female_rate == -1
        @battle_properties[:gender]  = 0
      elsif primary_data.female_rate == 0
        @battle_properties[:gender]  = 1
      elsif primary_data.female_rate == 100
        @battle_properties[:gender]  = 2
      else
        gender = %w[i m f].index(gender.downcase).to_i if gender.is_a?(String)
        @battle_properties[:gender]  = gender.clamp(0, 2)
      end
    end

    # Restore the battler's property original value
    def restore_gender
      @battle_properties.remove(:gender)
    end

    # Return the battler's combat property
    # @return [Integer]
    def ability
      return @battle_properties[:ability] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def ability=(value)
      return log_error("Wrong ability id : #{value}") unless GameData::Abilities.id_valid?(value)

      @battle_properties[:ability] = value
    end

    # Restore the battler's property original value
    def restore_ability
      @battle_properties.remove(:ability)
    end

    # Return the battler's combat property
    # @return [Integer]
    def rareness
      return @battle_properties[:rareness] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def rareness=(value)
      @battle_properties[:rareness] = value.clamp(0, 255)
    end

    # Restore the battler's property original value
    def restore_rareness
      @battle_properties.remove(:rareness)
    end

    # Return the battler's combat property
    # @return [Integer]
    def type1
      return @battle_properties[:type1] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def type1=(value)
      @battle_properties[:type1] = value
    end

    # Restore the battler's property original value
    def restore_type1
      @battle_properties.remove(:type1)
    end

    # Return the battler's combat property
    # @return [Integer]
    def type2
      return @battle_properties[:type2] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def type2=(value)
      @battle_properties[:type2] = value
    end

    # Restore the battler's property original value
    def restore_type2
      @battle_properties.remove(:type2)
    end

    # Return the battler's combat property
    # @return [Integer]
    def type3
      return @battle_properties[:type3] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def type3=(value)
      @battle_properties[:type3] = value
    end

    # Restore the battler's property original value
    def restore_type3
      @battle_properties.remove(:type3)
    end

    # Restore all Pokemon types
    def restore_types
      restore_type1
      restore_type2
      restore_type3
    end

    # Return the battler's combat property
    # @return [Integer]
    def loyalty
      return @battle_properties[:loyalty] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def loyalty=(value)
      @battle_properties[:loyalty] = value.clamp(0, 255)
    end

    # Restore the battler's property original value
    def restore_loyalty
      @battle_properties.remove(:loyalty)
    end

  end
end