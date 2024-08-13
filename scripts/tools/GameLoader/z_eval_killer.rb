# Module that solves the Memory leak caused by eval
module EvalKiller
  @interpreter_registry = {}
  @game_character_registry = {}

  # Module turning a string into an eval string
  module EvalString
    attr_accessor :method_symbol
  end

  def resolve_method_symbol(klass, script)
    return script.method_symbol if script.is_a?(EvalString)

    cleanup_script(script)
    script.extend(EvalString)
    registry = klass == Interpreter ? EvalKiller.interpreter_registry : EvalKiller.game_character_registry
    existing_method = registry[script]
    if existing_method
      script.method_symbol = existing_method
      return existing_method
    end

    new_method = build_method(script, registry, klass)
    script.method_symbol = new_method
    return new_method
  end

  def build_method(script, registry, klass)
    method_name = "eval_X#{registry.size}"
    klass.class_eval("def #{method_name}\n#{script}\nend")
    method_name = method_name.to_sym
    registry[script] = method_name
    return method_name
  end

  def cleanup_script(script)
    script.force_encoding('UTF-8')
    script.gsub!(/\n([(,])/, "\\1\n")
  end

  class << self
    attr_reader :interpreter_registry, :game_character_registry
  end
end