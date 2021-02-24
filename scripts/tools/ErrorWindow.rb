# This script allow to convert all event text to CSV
#
# To get access to this script write :
#   ScriptLoader.load_tool('ErrorWindow')
#
# To execute this script write :
#   ErrorWindow.run(error_text, *data_to_add)
module ErrorWindow
  class << self
    # Open the error window and let the user aknowledge it
    # @param error_text [String] Text stored inside Error.log
    # @param data_to_add [Array<String>] data to add to the error log as pictures
    def run(error_text, *data_to_add)
      ScriptLoader.load_tool('SaveToPicture')
      texts_to_show = cleanup_error_log(error_text)
      images_to_show = data_to_add.map { |i| SaveToPicture.run(data: i) }
      images_to_show << SaveToPicture.run(data: error_text)
      show_window_and_wait(texts_to_show, images_to_show)
    rescue Exception
      p $!, $!.backtrace
    end

    private

    # Function that generates the text to show
    # @param error_text [String]
    # @return [Array<String>]
    def cleanup_error_log(error_text)
      sections = error_text.split(/=+[^=]+=+\r*\n/).reject(&:empty?)
      backtraces = sections[1].split("\n")[0, 5].join("\n")
      message = sections[0].sub('Message', 'A script error happened')
      return message, "Backtraces:\n#{backtraces}"
    end

    # Function that shows the window and wait for the user to do something
    # @param texts_to_show [Array<String>] text to show into the window
    # @param images [Array<Image>]
    def show_window_and_wait(texts_to_show, images)
      window = LiteRGSS::DisplayWindow.new('Error', 960, 480, 1, 32, 20, false, false, false)
      create_text(window, texts_to_show)
      to_dispose = create_and_arrange_images(window, images)
      running = true
      window.on_closed = proc { running = false }
      while running
        window.update
        begin
          Graphics.window&.update_no_input
        rescue Exception
          0
        end
      end
      to_dispose.each { |bmp| bmp.dispose unless bmp.disposed? }
    end

    # Function that create the text to show into the window
    # @param window [LiteRGSS::Window]
    # @param texts_to_show [Array<String>]
    def create_text(window, texts_to_show)
      text = LiteRGSS::Text.new(0, window, window.width - 2, 96, 0, 16, texts_to_show[1], 2)
      text.draw_shadow = false
      text.fill_color = Color.new(220, 220, 220, 255)
      text.size = 13
      text = LiteRGSS::Text.new(0, window, 0, 0, 0, 16, append_message(texts_to_show[0]))
      text.draw_shadow = false
      text.fill_color = Color.new(220, 220, 220, 255)
      text.size = 13
    end

    # Function that append the text to show with a message
    # @param input [String]
    # @return [String]
    def append_message(input)
      return "#{input.strip}\n\nTake a snapshot of this window and report the issue if you can't fix it yourself!"
    end

    # Function that displays the images in reverse order starting from bottom right of the screen
    # @param window [LiteRGSS::Window]
    # @param images [Array<Image>]
    # @return [Array<Texture>]
    def create_and_arrange_images(window, images)
      y = window.height
      x = window.width
      min_y = y
      return images.map do |image|
        bmp = Texture.new(image.width, image.height)
        image.copy_to_bitmap(bmp)
        if (x - image.width) < 0
          x = window.width
          y = min_y
        end
        x -= image.width
        iy = y - image.height
        min_y = [iy, min_y].min
        LiteRGSS::Sprite.new(window).set_position(x, iy).bitmap = bmp
        image.dispose
        x -= 1
        next bmp
      end
    end
  end
end
