module Util
  module EventConvert
    class CommandConvert
      def initialize(list, *path)
        if list.is_a?(Integer)
          @list = load_path(list, *path)
        else
          @list = list
        end
        @labels = {}
        @choices = []
        @indent = 0
        @split_next = false
        convert
      end

      private

      def load_path(map_id, event_id, page)
        map = load_data(format('Data/Map%03d.rxdata', map_id))
        event = map.events[event_id]
        page = event.pages[page]
        return page.list
      end

      def convert
        @index = 0
        @master_list = @current_list = make_list
        perform_list_analysis
        write_ruby(STDOUT)
      end

      def make_list(previous = nil, parent = nil, label = nil)
        current_list = {
          begin: @index,
          end: nil,
          label: label,
          parent: parent,
          child: nil,
          previous: previous,
          internal_labels: [],
          next: nil
        }
        parent[:child] = current_list if parent && !parent[:child]
        previous[:next] = current_list if previous
        current_list
      end

      def perform_list_analysis
        while cmd = @list[@index]
          case cmd.code
          when 112 # Loop
            @current_list[:end] = @index - 1
            @current_list = make_list(nil, @current_list)
          when 413 # Redo loop <=> End of the loop
            raise "Unexpected 413 at index #{@index - 1}" unless @current_list[:parent]
            @current_list[:end] = @index - 1
            @current_list = make_list(@current_list[:parent], @current_list[:parent][:parent])
          when 118 # Label def
            @current_list[:end] = @index - 1
            @current_list = make_list(@current_list, @current_list[:parent], label = cmd.parameters.first)
            @labels[label] ||= @index
            taint_parent_loop_with_label(@current_list, label)
          when 402, 403, 111, 411 # Choice option, cancel, condition, else
            @current_list[:end] = @index - 1
            @current_list = make_list(@current_list, @current_list[:parent])
            @split_next = true
          when 404, 412 # End of choice / End of condition
            #@current_list[:end] = @index - 1
            #@current_list = make_list(@current_list, @current_list[:parent])
            @split_next = true
          else
            if @split_next
              @split_next = false
              @current_list[:end] = @index - 1
              @current_list = make_list(@current_list, @current_list[:parent])
            end
          end
          @index += 1
        end
        @current_list[:end] = @index - 1
      end

      # Function that tries to tell the internal labels of each parent of the current node
      def taint_parent_loop_with_label(parent, label)
        begin
          while parent[:previous]
            parent = parent[:previous]
          end
          parent[:internal_labels] << label
        end while(parent = parent[:parent])
      end

      def write_ruby(io)
        @labels.each do |label, line|
          io.puts("g#{line} = false # Flag to jump to #{label}")
        end
        write_ruby_loop(io, @master_list, "Safety loop")
      end

      def write_ruby_loop(io, node, comment = nil)
        io.puts(comment ? "#{' ' * @indent}loop do # #{comment}" : "#{' ' * @indent}loop do")
        @indent += 2
        current_list = node
        write_non_internal_labels(io, node)
        while current_list
          write_internal_list(io, node, current_list)
          # Manage other loop
          if(child = current_list[:child])
            write_ruby_loop(io, child)
          end
          current_list = current_list[:next]
        end
        io.puts("#{' ' * @indent}break") if node == @master_list
        write_end(io)
      end

      def write_internal_list(io, node, current_list)
        unless is_skipable_list(current_list)
          wrote_unless = write_unless(io, node, current_list)
          index = current_list[:begin]
          while index <= current_list[:end]
            index = write_ruby_translation(io, index, current_list)
            index += 1
          end
          write_end(io) if wrote_unless
        end
      end

      def write_non_internal_labels(io, node)
        non_internal_label = @labels.keys - node[:internal_labels]
        return if non_internal_label.empty?
        non_internal_label = non_internal_label.collect { |label| "g#{@labels[label]}" }
        io.puts("#{' ' * @indent}break if #{non_internal_label.join(' or ')}")
      end

      CONDITION_SKIP_UNLESS_LISTS = [402, 403, 111, 411]
      def write_unless(io, node, current_list)
        if CONDITION_SKIP_UNLESS_LISTS.include?(@list[current_list[:begin]].code)
          return false
        end
        skip_labels = node[:internal_labels] - [current_list[:label]]
        skip_labels = skip_labels.collect { |label| "g#{@labels[label]}" }
        if skip_labels.empty?
          return false
        else
          io.puts("#{' ' * @indent}unless #{skip_labels.join(' or ')}")
        end
        @indent += 2
        true
      end

      def write_end(io)
        @indent -= 2
        io.puts("#{' ' * @indent}end")
      end

      def write_ruby_translation(io, index, current_list)
        cmd = @list[index]
        param = cmd.parameters
        case cmd.code
        when 101
          io.puts("#{' ' * @indent}# Message : #{param.first}")
        when 118 # label def
          io.puts("#{' ' * @indent}g#{@labels[param.first]} = false # Simulate label #{param.first}")
        when 119 # Goto label
          io.puts("#{' ' * @indent}next(g#{@labels[param.first].to_i} = true) # Goto label #{param.first}")
        when 112, 413 # Loop / Loop end
          # do nothing
        when 402, 403 # Choice
          write_event_choice(io, cmd, current_list)
        when 111 # Conditions
          write_event_condition(io, cmd, current_list)
        when 113 # Break loop
          io.puts("#{' ' * @indent}break # Leave loop")
        when 404, 412 # End of condition / end of choice
          write_end(io)
          @choices.pop if cmd.code == 404
        end
        return index
      end

      def write_event_condition(io, cmd, current_list)
        internal_labels = @labels.keys - current_list[:internal_labels]
        internal_labels = internal_labels.collect { |label| "g#{@labels[label]}" }
        condition_string = "some_condition"
        if internal_labels.empty?
          io.puts("#{' ' * @indent}if #{condition_string}")
        else
          io.puts("#{' ' * @indent}if (#{condition_string}) or #{internal_labels.join(' or ')}")
        end
        @indent += 2
      end

      def write_event_choice(io, cmd, current_list)
        if @choices.last == cmd.indent
          write_end(io)
        else
          @choices << cmd.indent
        end
        internal_labels = @labels.keys - current_list[:internal_labels]
        internal_labels = internal_labels.collect { |label| "g#{@labels[label]}" }
        io.puts(cmd.code == 403 ? "#{' ' * @indent}# Cancel option" : "#{' ' * @indent}# Choice #{cmd.parameters.first}")
        condition_string = "some_choice"
        if internal_labels.empty?
          io.puts("#{' ' * @indent}if #{condition_string}")
        else
          io.puts("#{' ' * @indent}if (#{condition_string}) or #{internal_labels.join(' or ')}")
        end
        @indent += 2
      end

      def is_skipable_list(current_list)
        if current_list[:begin] == current_list[:end]
          code = @list[current_list[:end]].code
          return true if code == 112 || code == 413 || code == 0
        end
        return false
      end
    end
  end
end