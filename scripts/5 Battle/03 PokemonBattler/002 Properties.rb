
module PFM
  # Class defining a Pokemon during a battle, it aim to copy its properties but also to have the methods related to the battle.
  class PokemonBattler < Pokemon
    # List of the UIs able to omit the Illusion form of the Pokemon
    # @return [Array<Class>]
    ILLUSION_PROOF_SCENES = [GamePlay::Party_Menu, GamePlay::Summary]

    # Return the current ID of the Pokemon
    # If the current UI is one defined in PFM::PokemonBattler::ILLUSION_PROOF_SCENES
    # then it'll send the id saved before Illusion was triggered
    # @return [Integer]
    def id
      if @illusion && ILLUSION_PROOF_SCENES.include?($scene.class)
        index = ILLUSION_COPIED_PROPERTIES.index(:@id)
        return @properties_before_illusion[index]
      end

      return @id
    end

    # Return the current form of the Pokemon
    # If the current UI is one defined in PFM::PokemonBattler::ILLUSION_PROOF_SCENES
    # then it'll send the form saved before Illusion was triggered
    # @return [Integer]
    def form
      if @illusion && ILLUSION_PROOF_SCENES.include?($scene.class)
        index = ILLUSION_COPIED_PROPERTIES.index(:@form)
        return @properties_before_illusion[index]
      end

      return @form
    end

    # Return the current given name of the Pokemon
    # If the current UI is one defined in PFM::PokemonBattler::ILLUSION_PROOF_SCENES
    # then it'll send the given_name saved before Illusion was triggered
    # @return [String]
    def given_name
      if @illusion && ILLUSION_PROOF_SCENES.include?($scene.class)
        index = ILLUSION_COPIED_PROPERTIES.index(:@given_name)
        return @properties_before_illusion[index] || name
      end

      return super
    end

    # Return the current name of the Pokemon
    # If the current UI is one defined in PFM::PokemonBattler::ILLUSION_PROOF_SCENES
    # then it'll send the name of the original
    # @return [String]
    def name
      return Studio::Text.get(0, @step_remaining == 0 ? (@illusion && !ILLUSION_PROOF_SCENES.include?($scene.class) ? @id : original.id) : 0)
    end

    # Return the current code of the Pokemon
    # If the current UI is one defined in PFM::PokemonBattler::ILLUSION_PROOF_SCENES
    # then it'll send the code saved before Illusion was triggered
    # @return [Integer]
    def code
      if @illusion && ILLUSION_PROOF_SCENES.include?($scene.class)
        index = ILLUSION_COPIED_PROPERTIES.index(:@code)
        return @properties_before_illusion[index]
      end

      return @code
    end

    # Return the current ball ID the Pokemon was captured with
    # If the current UI is one defined in PFM::PokemonBattler::ILLUSION_PROOF_SCENES
    # then it'll send the ball id saved before Illusion was triggered
    # @return [Integer]
    def captured_with
      if @illusion && ILLUSION_PROOF_SCENES.include?($scene.class)
        index = ILLUSION_COPIED_PROPERTIES.index(:@captured_with)
        return @properties_before_illusion[index]
      end

      return @captured_with
    end

    # Return the cry file name of the Pokemon
    # If the Pokemon is under the effect of Illusion, returns the cry from the target of the ability
    # @return [String]
    def cry
      return @illusion&.cry if @illusion && !ILLUSION_PROOF_SCENES.include?($scene.class)

      return super
    end

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
      @battle_properties.delete(:atk_basis)
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
      @battle_properties.delete(:ats_basis)
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
      @battle_properties.delete(:dfe_basis)
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
      @battle_properties.delete(:dfs_basis)
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
      @battle_properties.delete(:spd_basis)
    end

    # Return the battler's combat property
    # @return [Integer]
    def nature_id
      return @battle_properties[:nature_id] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def nature_id=(value)
      @battle_properties[:nature_id] = value
    end

    # Restore the battler's property original value
    def restore_nature_id
      @battle_properties.delete(:nature_id)
    end

    # Return the battler's combat property
    # @return [Integer]
    def ability
      return @battle_properties[:ability] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def ability=(value)
      return log_error("Wrong ability id : #{value}") if data_ability(value).id != value && !value.nil?

      @battle_properties[:ability] = value
    end

    # Restore the battler's property original value
    def restore_ability
      @ability = original.ability
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
      @battle_properties.delete(:height)
    end

    # Return the battler's combat property
    # @return [Integer]
    def weight
      w = @battle_properties[:weight] || super

      w *= 2 if has_ability?(:heavy_metal)
      w /= 2 if has_ability?(:light_metal)
      return w
    end

    # Set the battler's combat property
    # @param value [Integer]
    def weight=(value)
      @battle_properties[:weight] = value
    end

    # Restore the battler's property original value
    def restore_weight
      @battle_properties.delete(:weight)
    end

    # Return the battler's combat property
    # @return [Integer]
    def gender
      if @illusion && $scene.is_a?(GamePlay::Party_Menu)
        index = ILLUSION_COPIED_PROPERTIES.index(:@gender)
        return @battle_properties[:gender] || @properties_before_illusion[index]
      end

      return @battle_properties[:gender] || super
    end

    # Set the battler's combat property
    # @param value [Integer]
    def gender=(value)
      return log_info("Gender changed to #{value}") && @battle_properties[:gender] = value.clamp(0, 2) if value.is_a?(Integer)

      @battle_properties[:gender] = super
    end

    # Restore the battler's property original value
    def restore_gender
      @battle_properties.delete(:gender)
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
      @battle_properties.delete(:rareness)
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
      @battle_properties.delete(:type1)
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
      @battle_properties.delete(:type2)
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
      @battle_properties.delete(:type3)
    end

    # Restore all Pokemon types
    def restore_types
      restore_type1
      restore_type2
      restore_type3
    end
  end
end
