data = File.read('scripts/LiteRGSS.rb')
data.gsub!(/\r\n +/, "\r\n")
data.gsub!('# @!attribute [rw] ', 'attr_accessor :')
data.gsub!('# @!attribute [r] ', 'attr_reader :')
data.gsub!('# @!attribute [w] ', 'attr_writer :')
data.gsub!('# @!attribute ', 'attr_accessor :')
data.gsub!(/# @!method(.*)\n((    #   .*\n)+)/) do
  caps = Regexp.last_match.captures
  definition = caps.shift
  caps.pop
  caps.first.sub!(/ +/, '')
  next caps.join("\r\n") + "    def#{definition}\n\n    end\n"
end
data.gsub!(/# @!method(.*)\n((  #   .*\n)+)/) do
  caps = Regexp.last_match.captures
  definition = caps.shift
  caps.pop
  caps.first.sub!(/ +/, '')
  next caps.join("\r\n") + "  def#{definition}\n\n  end\n"
end
data.gsub!(/( +)attr(.*)\n(.*)/, "\\3\n\\1attr\\2")
data.gsub!('#   ', '# ')

File.write('LiteRGSS.rb.yard.rb', data)
