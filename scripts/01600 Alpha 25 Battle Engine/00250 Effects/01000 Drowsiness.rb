module Battle
  module Effects
    # Drowsiness make the pokemon fall asleep after a certain amount of turns, applied by Yawn
    # @source https://bulbapedia.bulbagarden.net/wiki/Yawn_(move)
    class Drowsiness < PokemonTiedEffectBase
      # Create a new Pokemon tied effect
      # @param logic [Battle::Logic]
      # @param pokemon [PFM::PokemonBattler]
      # @param counter [Integer] (default:2)
      def initialize(logic, pokemon, counter = 2)
        super(logic, pokemon)
        self.counter = counter
        @logic.scene.display_message_and_wait(parse_text_with_pokemon(19, 667, @pokemon))
      end

      # If the effect can proc
      # @return [Boolean]
      def triggered?
        return @counter == 1
      end

      # Baton pass the substitute
      # @param target [PFM::PokemonBattler] Pokemon getting the substitute due to baton pass
      def baton_pass(target)
        kill
      end
      
      # Get the name of the effect
      # @return [Symbol]
      def name
        return :drowsiness
      end
    end
  end
end