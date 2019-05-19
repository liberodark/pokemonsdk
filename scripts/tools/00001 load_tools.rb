unless $RELEASE && $DEBUG
  puts 'Tools available ! Write use_tool in the terminal.'

  class Object
    # Use a specific tool
    # @param tool_name [Symbol] the tool you want to use
    # @param *args [Array] the argument of tools
    # @note It shows a list of tools if tool_name = nil
    def use_tool(tool_name = nil, *args)
      return Tools.tool_list unless tool_name
      Tools.use_tool(tool_name, *args)
      return nil
    end
  end

  # Module holding the tools logic
  module Tools
    @tool_list = {
      tool_list: { description: 'Show the list of tools', source: nil, receiver: Tools, method: :tool_list, args: [] }
    }

    @loaded_tools = [nil]

    module_function

    # Use a specific tool
    # @param tool_name [Symbol] the tool you want to use
    # @param *args [Array] the argument of tools
    def use_tool(tool_name, *args)
      tool = @tool_list[tool_name]
      if tool
        load_and_use_tool(tool, args)
      else
        puts "Tool #{tool_name} not found! Write use_tool() to get a list."
      end
    end

    # Show the tool list
    def tool_list
      @tool_list.each do |name, tool|
        puts "use_tool(:#{[name, *tool[:args]].join(', ')})"
        puts "\t#{tool[:description]}"
        puts "\tIn #{tool[:source]}::#{tool[:receiver]}##{tool[:method]}"
      end
      return nil
    end

    # Load & use a specific tool
    # @param tool [Hash] description of the tool
    # @param args [Array] arguments
    def load_and_use_tool(tool, args)
      source = tool[:source]
      unless @loaded_tools.include?(source)
        require File.join(File.dirname(File.expand_path(__FILE__)), source)
        @loaded_tools << source
      end
      tool[:receiver] = Object.const_get(tool[:receiver]) if tool[:receiver].is_a?(String)
      tool[:receiver].send(tool[:method], *args)
    end

    # Register a new tool
    # @param name [Symbol]
    # @param source [String, nil]
    # @param description [String]
    # @param receiver [String] const path to the Module that receive the method call
    # @param method_name [Symbol] name of the method that is called
    # @param *args [Array<String>] name of the parameters
    def register_tool(name, source, description, receiver, method_name, *args)
      @tool_list[name.to_sym] = {
        source: source,
        description: description,
        receiver: receiver.to_s,
        method: method_name.to_sym,
        args: args
      }
    end

    register_tool(:merge_pokemon_sprite, 'MergePokemonSprites.rb',
                  'Merge the Pokemon Sprite in less PNG file to allow faster copy of your project',
                  'Tools::MergePokemonSprite', :merge_all,
                  'skip_existing = true', 'delete_processed = false')
  end
end
