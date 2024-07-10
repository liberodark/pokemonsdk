unless ARGV.include?('studio')
  module GameData
    class Base
    end

    class Item < Base
      class << self
        def [](id)
          data_item(id)
        end
      end
    end
    Text = Studio::Text
  end
end
