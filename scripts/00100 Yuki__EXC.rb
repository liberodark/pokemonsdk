#encoding: utf-8

# Namespace that contains modules and classes written by Nuri Yuri
# @author Nuri Yuri
module Yuki
  # Module that allows the game to write and Error.log file if the Exception is not a SystemExit or a Reset
  #
  # Creation date : 2013, update : 26/09/2017
  # @author Nuri Yuri
  module EXC
    # Name of the current Game/Software
    Software = 'Pokémon SDK'

    module_function

    # Method that runs #build_error_log if the Exception is not a SystemExit or a Reset.
    # @overload run(e)
    #   The log is sent to Error.log
    #   @param e [Exception] the exception thrown by Ruby
    # @overload run(e, io)
    #   The log is sent to an io
    #   @param e [Exception] the exception thrown by Ruby
    #   @param io [#<<] the io that receive the log
    def run(e, io = nil)
      return if e.class == LiteRGSS::Graphics::ClosedWindowError
      raise if e.message.empty? or e.class.to_s == 'Reset'
      error_log = build_error_log(e)
      if io
        io << error_log
      else
        File.open('Error.log', 'wb') { |f| f << error_log }
        cc 0x01
        puts error_log
        cc 0x07
        system('pause') rescue nil
      end
    end

    # Method that build the error log.
    # @param e [Exception] the exception thrown by Ruby
    # @return [String] the log readable by anybody
    def build_error_log(e)
      str = ''
      return unless e.backtrace_locations
      source_arr = e.backtrace_locations[0]
      source_name = fix_source_path(source_arr.path.to_s)
      source_line = source_arr.lineno
      str << 'Erreur de script'.center(80, '=')
      # Formatage du message pour Windows
      str << format("\r\nMessage :\r\n%<message>s\r\n\r\n", message: e.message.to_s.gsub(/[\r\n]+/, "\r\n"))
      str << format("Type : %<type>s\r\n", type: e.class)
      str << format("Script : %<script>s\r\n", script: source_name)
      str << format("Ligne : %<line>d\r\n", line: source_line)
      str << format("Date : %<date>s\r\n", date: Time.new.strftime('%d/%m/%Y %H:%M:%S'))
      str << format("Logiciel : %<software>s %<version>s\r\n", software: Software, version: PSDK_Version)
      if @eval_script
        str << format("Script used by eval command : \r\n%<script>s\r\n\r\n", script: @eval_script)
      end
      str << 'Backtraces'.center(80, '=')
      str << "\r\n"
      index = e.backtrace_locations.size
      e.backtrace_locations.each do |i|
        index -= 1
        source_name = fix_source_path(i.path.to_s)
        str << format("[%<index>s] : %<script>s | ligne %<line>d %<method>s\r\n",
                      index: index, script: source_name, line: i.lineno, method: i.base_label)
      end
      str << 'Fin du log'.center(80, '=')
      return str
    end

    # Function that corrects the source path
    # @param source_name [String] the source name path
    # @return [String] the fixed source name
    def fix_source_path(source_name)
      source_name.sub(File.expand_path('.'), nil.to_s)
    end

    # Sets the script used by the eval command
    # @param script [String, nil] the script used in the eval command
    def set_eval_script(script)
      if script
        @eval_script = script
      else
        @eval_script = nil
      end
    end

    # Get the eval script used by the current eval command
    # @return [String, nil]
    def get_eval_script
      return @eval_script
    end
  end
end
