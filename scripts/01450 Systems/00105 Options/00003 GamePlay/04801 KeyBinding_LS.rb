module GamePlay
  class KeyBinding
    class << self
      # Load the Inputs
      def load_inputs
        unless File.exist?(input_filename)
          normalize_inputs
          save_inputs
        end
        load_inputs_internal
        normalize_inputs
      rescue StandardError
        normalize_inputs
        save_inputs
      end

      # Perform the internal operation of loading the inputs
      def load_inputs_internal
        data = JSON.parse(File.read(input_filename), { symbolize_names: true })
        raise 'Bad Input data' unless data.is_a?(Hash)
        UI::KeyBindingViewer::KEYS.each do |infos|
          key = infos[0]
          next unless (key_values = data[key]) && key_values.is_a?(Array)

          Input::Keys[key].clear
          Input::Keys[key].concat(key_values.collect(&:to_i))
        end
        Input.main_joy = data[:main_joy] || Input.main_joy
        Input.x_axis = Input.const_get(data[:x_axis]) if is_axis_valid?(data, :x_axis)
        Input.y_axis = Input.const_get(data[:y_axis]) if is_axis_valid?(data, :y_axis)
      end

      # Test if the axis from JSON data is valid
      def is_axis_valid?(data, axis_attr)
        return false unless data[axis_attr].is_a?(Symbol) || data[axis_attr].is_a?(String)
        return Input.const_defined?(data[axis_attr])
      end

      # Normalize the Input::Keys contents in order to have a correct display in the UI
      def normalize_inputs
        Input::Keys.each do |_key, key_array|
          next if key_array.size >= 5
          first_key = key_array[0] || 0
          joy_key = key_array.find { |value| value < 0 } || first_key
          (key_array.size - (joy_key == first_key ? 0 : 1)).upto(3) do |index|
            key_array[index] = first_key
          end
          key_array[4] = joy_key
        end
      end

      # Save the inputs in the right file
      def save_inputs
        data = { main_joy: Input.main_joy }
        data[:x_axis] = Input.constants.find { |e| Input.const_get(e) == Input.x_axis }
        data[:y_axis] = Input.constants.find { |e| Input.const_get(e) == Input.y_axis }
        UI::KeyBindingViewer::KEYS.each do |infos|
          data[infos[0]] = Input::Keys[infos[0]].clone
        end
        File.open(input_filename, 'w') { |f| JSON.dump(data, f) }
      end

      # Return the filename with path of the inputs.yml file
      def input_filename
        directory = File.dirname(Save.save_filename)
        Dir.mkdir!(directory) unless Dir.exist?(directory)
        File.join(directory, 'input.json')
      end
    end
    Graphics.on_start { load_inputs }
  end
end
