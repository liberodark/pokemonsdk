module Battle
  module Effects
    # Class that manage DestinyBond effect. Works together with Move::DestinyBond.
    # @see https://pokemondb.net/move/destiny-bond
    # @see https://bulbapedia.bulbagarden.net/wiki/Destiny_Bond_(move)
    # @see https://www.pokepedia.fr/Lien_du_Destin
    class DestinyBond < PokemonTiedEffectBase
      def name
        :destiny_bond
      end

      # Note
      # Effect managed in DamageHandler on_post_damage_death hook 'PSDK Post damage: Destiny Bond'
    end
  end
end