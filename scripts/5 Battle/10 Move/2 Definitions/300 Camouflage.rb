module Battle
  class Move
    # Camouflage causes the user to change its type based on the current terrain.
    # @see https://pokemondb.net/move/camouflage
    # @see https://bulbapedia.bulbagarden.net/wiki/Camouflage_(move)
    # @see https://www.pokepedia.fr/Camouflage
    class Camouflage < Move
      include Mechanics::LocationBased

      private

      # Play the move animation
      # @param user [PFM::PokemonBattler] user of the move
      # @param targets [Array<PFM::PokemonBattler>] expected targets
      def play_animation(user, targets)
        super # TODO, change the animation to match the type color
      end

      # Function that deals the effect to the pokemon
      # @param user [PFM::PokemonBattler] user of the move
      # @param actual_targets [Array<PFM::PokemonBattler>] targets that will be affected by the move
      def deal_effect(user, actual_targets)
        type = data_type(element_by_location).id
        actual_targets.each do |target|
          target.change_types(type)
          scene.display_message_and_wait(deal_message(user, target, type))
        end
      end

      def deal_message(user, target, type)
        parse_text_with_pokemon(19, 899, target, { '[VAR TYPE(0001)]' => data_type(type).name })
      end

      # Element by location type.
      # @return [Hash<Symbol, Array<Symbol>]
      def element_table
        TYPE_BY_LOCATION
      end

      class << self
        def reset
          const_set(:TYPE_BY_LOCATION, {})
        end

        def register(loc, type)
          TYPE_BY_LOCATION[loc] ||= []
          TYPE_BY_LOCATION[loc] << type
          TYPE_BY_LOCATION[loc].uniq!
        end
      end

      reset
      register(:__undef__, :normal)
      register(:regular_ground, :normal)
      register(:building, :normal)
      register(:grass, :grass)
      register(:desert, :ground)
      register(:cave, :rock)
      register(:water, :water)
      register(:shallow_water, :ground)
      register(:snow, :ice)
      register(:icy_cave, :ice)
      register(:volcanic, :fire)
      register(:burial, :ghost)
      register(:soaring, :flying)
      register(:misty_terrain, :fairy)
      register(:grassy_terrain, :grass)
      register(:electric_terrain, :electric)
      register(:psychic_terrain, :psychic)
      register(:space, :dragon)
      register(:ultra_space, :dragon)
    end
    register(:s_camouflage, Camouflage)
  end
end
