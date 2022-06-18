def write_csv(id, lines)
  CSV.open("Data/Text/Dialogs/#{Studio::Text::CSV_BASE + id}.csv", 'wb') do |csv|
    csv << %w[en fr it de es ko kana]
    lines.each { |line| csv << line }
  end
end

def read_text_file(lang)
  Marshal.load(Zlib::Inflate.inflate(load_data("Data/Text/#{lang}.dat")))
end

def generate_csv
  texts = %w[en fr it de es ko kana].collect { |lang| read_text_file(lang) }
  range = 0...texts.size

  texts.first.size.times do |id|
    lines = Array.new(texts.first[id].size) do |line_id|
      range.collect { |lang_id| texts.dig(lang_id, id, line_id) }
    end
    write_csv(id, lines)
    GC.start
  end
end

generate_csv
