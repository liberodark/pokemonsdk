module Battle
  class Visual3D
    # Module holding all the Battle 3D Transitions
    module Transition3D
      # Base class of all transitions
      class Base < Battle::Visual::Transition::Base

        ANIMATION_DURATION = 0.75

        # Create a new transition
        # @param scene [Battle::Scene]
        # @param screenshot [Texture]
        # @param camera [Fake3D::Camera]
        # @param camera_positionner [Visual3D::CameraPositionner]
        def initialize(scene, screenshot, camera, camera_positionner)
          super(scene, screenshot)
          @camera = camera
          @camera_positionner = camera_positionner
        end
      end

      class RBYTrainer < Battle::Visual::Transition::RBYTrainer

        ANIMATION_DURATION = 0.75
        # Create a new transition
        # @param scene [Battle::Scene]
        # @param screenshot [Texture]
        # @param camera [Fake3D::Camera]
        # @param camera_positionner [Visual3D::CameraPositionner]
        def initialize(scene, screenshot, camera, camera_positionner)
          super(scene, screenshot)
          @camera = camera
          @camera_positionner = camera_positionner
        end

        # Function that starts the Enemy send animation
        def start_enemy_send_animation
          log_debug('start_enemy_send_animation')
          ya = Yuki::Animation
          pre_animation = ya.wait(1.8)
          pre_animation.parallel_add(create_enemy_send_animation)

          animation = pre_animation
          animation.parallel_add(ya.send_command_to(self, :show_enemy_send_message))
          animation.play_before(ya.message_locked_animation)
          animation.play_before(ya.send_command_to(self, :start_actor_send_animation))
          animation.start
          @animations << animation
        end
      end
    end

    # Method that show the pre_transition of the battle
    def show_pre_transition
      # return if debug? && ARGV.includes?('skip_battle_transition')
      # @type [Battle::Visual::RBJ_WildTransition]
      @transition = battle_transition.new(@scene, @screenshot, @camera, @camera_positionner)
      @animations << @transition
      @transition.pre_transition
      @locking = true
    end

    # Return the current battle transition
    # @return [Class]
    def battle_transition
      collection = $game_temp.trainer_battle ? TRAINER_TRANSITIONS_3D : WILD_TRANSITIONS_3D
      transition_class = collection[0] #$game_variables[Yuki::Var::TrainerTransitionType]]
      log_debug("Choosen transition class : #{transition_class}")
      return transition_class
    end

    class << self
      # Register the transition resource type for a specific transition
      # @note If no resource type was registered, will send the default sprite one
      # @param id [Integer] id of the transition
      # @param resource_type [Symbol] the symbol of the resource_type (:sprite, :artwork_full, :artwork_small)
      def register_transition_resource(id, resource_type)
        return unless id.is_a?(Integer)
        return unless resource_type.is_a?(Symbol)

        TRANSITION_RESOURCE_TYPE3D[id] = resource_type
      end

      # Return the transition resource type for a given transition ID
      # @param id [Integer] ID of the transition
      # @return [Symbol]
      def transition_resource_type_for(id)
        resource_type = TRANSITION_RESOURCE_TYPE3D[id]
        return :sprite unless resource_type

        return resource_type
      end
    end

    # List of the resource type for each transition
    # @return [Hash{ Integer => Symbol }]
    TRANSITION_RESOURCE_TYPE3D = {}
    TRANSITION_RESOURCE_TYPE3D.default = :sprite

    # List of Wild Transitions
    # @return [Hash{ Integer => Class<Transition3D::Base> }]
    WILD_TRANSITIONS_3D = {}

    # List of Trainer Transitions
    # @return [Hash{ Integer => Class<Transition3D::Base> }]
    TRAINER_TRANSITIONS_3D = {}
  end
end

