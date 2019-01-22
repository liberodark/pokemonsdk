module Yuki
  class Particle_Object
    ACTION_HANDLERS = {}
    ACTION_HANDLERS_ORDER = []

    # Add a new action handler
    # @param name [Symbol] name of the action
    # @param before [Symbol, nil] tell to put this handler before another handler
    def self.add_handler(name, before = nil, &block)
      unless ACTION_HANDLERS_ORDER.include?(name)
        index = before ? ACTION_HANDLERS_ORDER.index(before) : nil
        index ||= ACTION_HANDLERS_ORDER.size
        ACTION_HANDLERS_ORDER.insert(index, name)
      end
      ACTION_HANDLERS[name] = block
    end

    add_handler(:state) { |data| @state = data }
    add_handler(:on_chara_move_end) { |data| execute_action(data) if @character.movable? }
    add_handler(:zoom) { |data| @sprite.zoom = data * 1 }
    add_handler(:file) do |data|
      @sprite.bitmap = RPG::Cache.particle(data)
      @ox = (@sprite.bitmap.width * @sprite.zoom_x) / 2
      @oy = (@sprite.bitmap.height * @sprite.zoom_y) / 2
    end
    add_handler(:sound) do |data|
      next unless @sound_files
      @@sound_counter = (@@sound_counter + 1) % @sound_count
      if (sf = @sound_files[@@sound_counter])
        Audio.se_play(data.fetch(2, sf), data.fetch(0, 100), data.fetch(1, 100) - 5 + rand(10))
      end
    end
    add_handler(:rect_mode) { |data| @rect_mode = data }
    add_handler(:position) { |data| @position_type = data }
    add_handler(:angle) { |data| @sprite.angle = data }
    add_handler(:add_z) { |data| @add_z = data }
    add_handler(:oy_offset) do |data|
      if data.is_a?(Array)
        case data[0]
        when :range
          @oy_off = (data[1] + rand(data[2]))
        when :add
          @oy_off += data[1]
        when :add_sign_rand
          @oy_sign = (rand(2).zero? ? -1.0 : 1.0) unless @sign
          @oy_off += (@oy_sign * data[1])
        end
      else
        @oy_off = data
      end
    end
    add_handler(:ox_offset) do |data|
      if data.is_a?(Array)
        case data[0]
        when :range
          @ox_off = (data[1] + rand(data[2]))
        when :add
          @ox_off += data[1]
        when :add_sign_rand
          @ox_sign = (rand(2).zero? ? -1.0 : 1.0) unless @sign
          @ox_off += (@ox_sign * data[1])
        end
      else
        @ox_off = data
      end
    end
    add_handler(:opacity) { |data| @sprite.opacity = data }
    # Should be the last handlers : use the before argument when you add new handlers.
    add_handler(:chara) do |data|
      cw = @sprite.bitmap.width / 4
      ch = @sprite.bitmap.height / 4
      sx = @character.pattern * cw
      sy = (@character.direction - 2) / 2 * ch
      @sprite.src_rect.set(sx, sy, cw, ch)
      @ox = cw / 2
      @oy = ch / 2
    end
    add_handler(:rect) do |data|
      # dim = (data[0].is_a?(Array) ? dim = data[rand(data.size)] : data)
      dim = data
      dim = dim[rand(dim.size)] if dim.first.is_a?(Array)
      @sprite.src_rect.set(*dim)
      next if @rect_mode == :brut
      @ox = dim[2] / 2
      @oy = dim[3] / 2
    end
  end
end
