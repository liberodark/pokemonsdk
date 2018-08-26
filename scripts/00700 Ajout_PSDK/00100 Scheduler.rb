#encoding: utf-8

# Module that allows you to schedule some tasks and run them at the right time
# 
# The Scheduler has a @tasks Hash that is organized the following way:
#   @tasks[reason][class] = [tasks]
#   reason is one of the following reasons :
#     :on_update => during Graphics.update
#     :on_scene_switch => before going outside of the #main function of the scene (if called)
#     :on_dispose => during the dispose process (not called yet)
#     :on_init => at the begining of #main before Graphics.transition
#     :on_warp_start => at the begining of player warp process (first action)
#     :on_warp_process => after the player has been teleported but before the states has changed
#     :on_warp_end => before the transition starts
#     :on_hour_update => When the current hour change (ex: refresh groups)
#   class is a Class Object related to the scene where the Scheduler starts
#
# The Sheduler also has a @storage Hash that is used by the tasks to store informations
module Scheduler
  module_function
  # Initialize the Scheduler with no task and nothing in the storage
  def init
    @tasks = {
      :on_update => {},       #> Lors de la mise à jour des Graphics
      :on_scene_switch => {}, #> Lors d'un changement de scène
      :on_dispose => {},      #> Lorsqu'une scène s'efface
      :on_init => {},         #> Lorsqu'une scène s'initialise
      :on_warp_start => {},   #> Au début de la téléportation
      :on_warp_process => {}, #> Pendant le traitement de la téléportation
      :on_warp_end => {},     #> A la fin de la téléportation
      :on_hour_update => {},  #> Au moment où l'heure change
      :on_getting_tileset_name => {}, #> Au moment où $game_map.setup est appelé, que $game_map.map_id est affecté au nouvel id et que le fichier du tileset est demandé.
    }
    @storage = {}
  end
  init
  # Start tasks that are related to a specific reason
  # @param reason [Symbol] reason explained at the top of the page
  # @param _class [Class, :any] the class of the scene
  def start(reason, _class = $scene.class)
    task_hash = @tasks[reason]
    return unless task_hash #> Bad reason
    start(reason, :any) if _class != :any
    task_array = task_hash[_class]
    return unless task_array #> No task for this class
    task = nil
    task_array.each { |task| task.start }
  end
  # Remove a task
  # @param reason [Symbol] the reason
  # @param _class [Class, :any] the class of the scene
  # @param name [String] the name that describe the task
  # @param priority [Integer] its priority
  def __remove_task(reason, _class, name, priority)
    task_hash = @tasks[reason]
    return unless task_hash #> Bad reason
    task_array = task_hash[_class]
    return unless task_array
    task_array.delete_if { |obj| obj.priority == priority and obj.name == name }
  end
  # add a task (and sort them by priority)
  # @param reason [Symbol] the reason
  # @param _class [Class, :any] the class of the scene
  # @param task [ProcTask, MessageTask] the task to run
  def __add_task(reason, _class, task)
    task_hash = @tasks[reason]
    return unless task_hash #> Bad reason
    task_array = task_hash[_class] || []
    task_hash[_class] = task_array
    task_array << task
    a = b = nil
    task_array.sort! { |a, b| a.priority <=> b.priority }
  end
  # Description of a Task that execute a Proc
  class ProcTask
    # Priority of the task
    # @return [Integer]
    attr_reader :priority
    # Name that describe the task
    # @return [String]
    attr_reader :name
    # Initialize a ProcTask with its name, priority and the Proc it executes
    # @param name [String] name that describe the task
    # @param priority [Integer] the priority of the task
    # @param _proc [Proc] the proc (with no param) of the task
    def initialize(name, priority, _proc)
      @name = name
      @priority = -priority
      @proc = _proc
    end
    # Invoke the #call method of the proc
    def start
      @proc.call
    end
  end
  # Add a proc task to the Scheduler
  # @param reason [Symbol] the reason
  # @param _class [Class] the class of the scene
  # @param name [String] the name that describe the task
  # @param priority [Integer] the priority of the task
  # @param _proc [Proc] the Proc object of the task
  def add_proc(reason, _class, name, priority, _proc)
    __add_task(reason, _class, ProcTask.new(name, priority, _proc))
  end
  # Describe a Task that send a message to a specific object
  class MessageTask
    # Priority of the task
    # @return [Integer]
    attr_reader :priority
    # Name that describe the task
    # @return [String]
    attr_reader :name
    # Initialize a MessageTask with its name, priority, the object and the message to send
    # @param name [String] name that describe the task
    # @param priority [Integer] the priority of the task
    # @param object [Object] the object that receive the message
    # @param message [Array<Symbol, *args>] the message to send
    def initialize(name, priority, object, message)
      @name = name
      @priority = -priority
      @object = object
      @message = message
    end
    # Send the message to the object
    def start
      @object.send(*@message)
    end
  end
  # Add a message task to the Scheduler
  # @param reason [Symbol] the reason
  # @param _class [Class, :any] the class of the scene
  # @param name [String] name that describe the task
  # @param priority [Integer] the priority of the task
  # @param object [Object] the object that receive the message
  # @param message [Array<Symbol, *args>] the message to send
  def add_message(reason, _class, name, priority, object, *message)
    __add_task(reason, _class, MessageTask.new(name, priority, object, message))
  end
  # Return the object of the Boot Scene (usually Scene_Title)
  # @return [Object]
  def get_boot_scene
    if Config.const_defined?(:EditSystemTags)
      return Yuki::SystemTagEditor
    end
    if PARGV[:worldmap]
      return Yuki::WorldMapEditor
    end
    if PARGV[:"animation-editor"]
      return Yuki::AnimationEditor
    end
    test = PARGV[:test].to_s #ARGV.grep(/--test=./).first.to_s.gsub("--test=","")
    return Scene_Title.new if test.empty?
    test = "tests/#{test}.rb"
    return Tester.new(test) if File.exist?(test)
    return Scene_Title.new
  end
end
