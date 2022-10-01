# frozen_string_literal: true

# Script helping Pokemon Studio & PSDK to communicate
# This script is automatically launched if psdk was launched with studio argument
require_relative '../../../keep/legacy_psdk_config'
module Studio
  module_function

  # Load the studio interface
  def start
    return if @handler

    ScriptLoader.start
    ScriptLoader.load_tool('Studio/Handler')
    PSDK_CONFIG.send(:initialize) rescue nil # Normally not useful for post studio projects
    @handler = Handler.new
    @handler.start
  end
end

require 'json'

module Kernel
  $original_stdout = STDOUT.dup
  $original_stderr = STDERR.dup
  STDOUT.reopen(IO::NULL)
  STDERR.reopen(IO::NULL)

  def puts(*args)
    message = args.join("\n").gsub(/\033\[[0-9]+m/, '').strip
    return if message.empty?

    $original_stdout.puts({ type: :kernel_puts, message: message }.to_json)
  end

  def p(*args)
    message = args.map(&:inspect).join("\n").gsub(/\033\[[0-9]+m/, '').strip
    return if message.empty?

    $original_stdout.puts({ type: :kernel_p, message: message }.to_json)
  end

  def print(*args)
    message = args.join("\n").gsub(/\033\[[0-9]+m/, '').strip
    return if message.empty?

    $original_stdout.puts({ type: :kernel_print, message: message }.to_json)
  end
end
