module UI
  module Storage
    # Class that handle all the logic related to cursor movement between each party of the UI
    class CursorHandler
      # Create a cusor handler
      # @param cursor [Cursor]
      def initialize(cursor)
        @cursor = cursor
        @row_index = 0
        @column_index = 0
      end

      # Get the cursor mode
      # @return [Symbol] :box, :party, :box_choice
      def mode
        return :box if @cursor.inbox
        return :box_choice if @cursor.select_box

        return :party
      end

      # Get the index of the cursor
      # @return [Integer]
      def index
        @cursor.index
      end

      # Move the cursor to the right
      # @return [Boolean] if the action was a success
      def move_right
        @cursor.visible = true
        return false if @cursor.select_box

        return @cursor.inbox ? move_right_inbox : move_right_party
      end

      # Move the cursor to the left
      # @return [Boolean] if the action was a success
      def move_left
        @cursor.visible = true
        return false if @cursor.select_box

        return @cursor.inbox ? move_left_inbox : move_left_party
      end

      # Move the cursor up
      # @return [Boolean] if the action was a success
      def move_up
        @cursor.visible = true

        if @cursor.inbox && @cursor.index <= 5
          @row_index = @cursor.index
          @cursor.select_box = true
        elsif @cursor.select_box
          @cursor.inbox = true
          @cursor.index = @row_index + 24
        else  
          @cursor.index -= @cursor.inbox ? 6 : 2
        end
        return true
      end

      # Move the cursor down
      # @return [Boolean] if the action was a success
      def move_down
        @cursor.visible = true
        if @cursor.select_box
          @cursor.inbox = true
          @cursor.index = @cursor.index
        else
          @cursor.index += @cursor.inbox ? 6 : 2
        end
        return true
      end

      private

      # Move the cursor to the right in the box
      # @return [Boolean] if the action was a success
      def move_right_inbox
        if @cursor.index % 6 == 5
          @column_index = @cursor.index
          @cursor.inbox = false
          @cursor.index = (@cursor.index / 11.5).floor * 2
        else
          @cursor.index += 1
        end

        return true
      end

      # Move the cursor to the right in the party
      # @return [Boolean] if the action was a success
      def move_right_party
        if @cursor.index.odd?
          @cursor.inbox = true
          @cursor.index = @column_index - 5
        else
          @cursor.index += 1
        end

        return true
      end

      # Move the cursor to the left in the box
      # @return [Boolean] if the action was a success
      def move_left_inbox
        if @cursor.index % 6 == 0
          @column_index = @cursor.index + 5
          @cursor.inbox = false
          @cursor.index = @cursor.index / 9 * 2 
          @cursor.index += 1
        else  
          @cursor.index -= 1
        end

        return true
      end

      # Move the cursor to the left in the party
      # @return [Boolean] if the action was a success
      def move_left_party
        if @cursor.index.even?
          @cursor.inbox = true
          @cursor.index = @column_index
        else
          @cursor.index -= 1
        end

        return true
      end
    end
  end
end
