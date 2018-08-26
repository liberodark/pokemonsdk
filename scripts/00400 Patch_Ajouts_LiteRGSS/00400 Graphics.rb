#encoding: utf-8

# Module that manage the general graphic display
module Graphics
  @update = method(:update)
  @stop = method(:stop)
  @start = method(:start)
  @freeze = method(:freeze)
  @transition = method(:transition)
  # Time of a frame
  DT = 1 / 60.0
  # Time of a frame + potential error
  DT2 = DT - 1 / 600.0
  # Opposite of the time of a frame
  DTM = - DT
  @on_start = []
  @last_scene = nil
  module_function
  # Define a block that should be called when Graphics.start has been called
  # @param block [Proc] the block to call
  def on_start(&block)
    @on_start << block
  end
  # Start the Graphic module (show the Window and call some things)
  def start
    @start.call
    @on_start.each { |block| block.call }
    @on_start.clear
    STDOUT.sync = true unless STDOUT.tty?
    @cmd_thread = Thread.new do 
      while true
        print "Commande : "
        @__cmd_to_eval = STDIN.gets.chomp
        sleep
      end
    end
    @time = Time.new
    @delta_time = 0
    @frame_to_skip = 0
    @ruby_time = Time.new
    @no_mouse = (Config.const_defined?(:DisableMouse) and Config::DisableMouse and !PARGV[:tags])
    init_sprite
  end
  # Update the screen with the current frame state
  def update
    ::Scheduler.start(:on_update)
    if @last_scene != $scene
      sort_z
      @last_scene = $scene
    end
    # Update FPS
    fps_update
    update_manage
    unless @no_mouse
      Mouse.moved = (@mouse.x != Mouse.x or @mouse.y != Mouse.y)
      @mouse.x = Mouse.x
      @mouse.y = Mouse.y
    end
    FMOD::System.update
    update_cmd_eval if @__cmd_to_eval
  end
  # Manage the frame display (skip frames, show multiple frames)
  def update_manage
    # Auto skip
    if @frame_to_skip > 0
      @frame_to_skip -= 1
      Graphics.frame_count += 1
      Graphics.update_only_input
      return
    end
    # Adding the time Ruby worked (because the GPU will equilibrate its work time)
    @delta_time += (Time.new - @ruby_time)
    # Estimating frame duration
    t = Time.new
    @update.call
    dt = Time.new - t #> Time of the elapsed frame ~0.016
    #fps = (1 / dt).ceil / 10 * 10
    dt -= DT #> Substract the time of a constant frame if the result is > 0 we'll need to skip frames
    @delta_time += dt # Adding the difference
    if @delta_time >= DT
      #puts ">>>DT #{@delta_time}"
      @frame_to_skip = (@delta_time / DT).to_i
      @delta_time -= @frame_to_skip * DT
    elsif @delta_time <= DTM
      #Saving framecount
      #fc = frame_count
      #puts "<<<DTM #{@delta_time}"
      while @delta_time <= DTM
        t = Time.new
        update_no_input
        @delta_time += (Time.new - t)
      end
      #Graphics.frame_count = fc
    end
    @ruby_time = Time.new
  end
  # Update the FPS counter
  def fps_update
    if frame_count % 60 == 0
      dt = Time.new - @time
      @time = Time.new
      @text.text = (60 / dt).round.to_s if dt * 10 >= 1
    end
  end
  # Stop the Graphic display
  def stop
    @text.dispose unless !@text or @text.disposed?
    @mouse.dispose unless !@mouse or @mouse.disposed?
    @cmd_thread.kill if @cmd_thread
    @stop.call
  end
  # Make the Game wait n frames
  # @param n [Integer]
  # @yield [] a block performing action after each Graphics.update (optionnal)
  def wait(n)
    n.times do
      update
      yield if block_given?
    end
  end
  # Make the Graphics freeze
  def freeze
    @mouse.visible = false unless @no_mouse
    @text.load_color(1)
    wait(6)
    @freeze.call
  end
  # Perform a Transition
  # @param args [Array<Integer, LiteRGSS::Bitmap>] number of frame to perform the transition and the bitmap to use if needed
  def transition(*args)
    sort_z
    @transition.call(*args)
    @text.load_color(9)
    @mouse.visible = true unless @no_mouse
    @ruby_time = Time.new
  end
  # Reset the counter
  def frame_reset
    @ruby_time = Time.new
  end
  # Init the Sprite used by the Graphics module
  def init_sprite
    return if @text and !@text.disposed?
    @text = Text.new(0, nil, 0, 0, 318, 13, "0", 2, 1).load_color(9)
    @text.z = 200_000
    @text.visible = PARGV[:"show-fps"]#!(ARGV.include?("--hide-fps") || ARGV.include?("--tags") || ARGV.include?("--animation-editor"))
    unless @no_mouse
      @mouse = Sprite.new
      @mouse.z = 200_001
      if Config.const_defined?(:MouseSkin) and RPG::Cache.windowskin_exist?(Config::MouseSkin)
        @mouse.bitmap = RPG::Cache.windowskin(Config::MouseSkin)
      else
        @mouse.bitmap = Bitmap.new(10, 10)
        @mouse.bitmap.fill_rect(0, 0, 5, 5, Color.new(0, 0, 0, 255))
        @mouse.bitmap.fill_rect(1, 1, 4, 4, Color.new(255, 255, 255, 255))
        @mouse.bitmap.update
      end
    end
  end
  # If Graphics will skip this frame (prevent hard working)
  def skipping_frame?
    return @frame_to_skip > 0
  end
  # Sort the Graphical element by their z coordinate (in the Graphic Stack)
  def sort_z
    @__elementtable.sort! do |a, b| 
      s = a.z <=> b.z
      next(a.__index__ <=> b.__index__) if s == 0
      next(s)
    end
    reload_stack
  end
  # Eval a command from the console
  def update_cmd_eval
    cmd = @__cmd_to_eval
    @__cmd_to_eval = nil
    begin
      Object.instance_eval(cmd)
    rescue Exception
      print "\r"
      puts "#{$!.class} : #{$!.message}"
      puts $!.backtrace
    end
    @cmd_thread.wakeup
  end
end
