require 'csv'
require 'json'
class CSV
  # Class that helps to encode object into a CSV file
  #
  # How to encode a object collection to CSV :
  #   # Example with a Point
  #   enc = CSV::ObjectEncoder.new(Point)
  #   enc.add_property(:x, 'X Position')
  #   enc.add_property(:y, 'Y Position')
  #   CSV.open('filename.csv', 'w') do |csv|
  #     enc.write_collection(csv, points)
  #   end
  #
  # How to decode a object collection from CSV :
  #   # With the last example, define the encoder the same way
  #   collection = CSV.open('filename.csv', 'r') do |csv|
  #     break(enc.read_collection(csv))
  #   end
  class ObjectEncoder
    # Create a new ObjectEncoder
    # @param klass [Class] the class of the object to instanciate for the decoding process
    def initialize(klass)
      @class = klass
      @props = []
      @csv_cols = []
      @setters = []
    end

    # Add a property to the CSV file
    # @param prop [Symbol] name of the property (attr_accessor) in the Objects to encode
    # @param column_name [String] name of the column for the Header
    def add_property(prop, column_name)
      @props << prop
      @csv_cols << column_name.downcase
      @setters << :"#{prop}="
    end

    # Encode an object into a CSV file
    # @param csv [CSV] the csv file
    # @param object [Object] the object to encode
    def encode(csv, object)
      csv << pri_encode(object)
    end

    # Write the header in the CSV file
    # @param csv [CSV] the csv file
    def write_header(csv)
      csv << pri_header
    end

    # Write a collection in the csv file (including the header)
    # @param csv [CSV] the csv file
    # @param collection [Array<Object>] the collection of objects
    def write_collection(csv, collection)
      write_header(csv)
      collection.each { |object| encode(csv, object) }
    end

    # Read a collection from a csv file (header should be present as first line)
    # @param csv [CSV]
    # @return [Array<Object>]
    def read_collection(csv)
      collection = csv.read
      header = collection.shift
      return pri_decode_collection(header, collection)
    end

    private

    def pri_encode(object)
      @props.collect { |property| object.send(property) }
    end

    def pri_safe_object_conv(object)
      return object if object.is_a?(Comparable)
      return "json:#{object.to_json}"
    end

    def pri_header
      @csv_cols.clone
    end

    def pri_decode_object(array)
      object = @class.allocate
      @setters.each_with_index { |setter, index| object.send(setter, pri_convert(array[index])) }
      return object
    end

    def pri_convert(object)
      return object unless object.is_a?(String) && object.start_with?('json:')
      JSON.parse(object[5..-1], symbolize_names: true)
    end

    def pri_decode_collection(header, collection)
      value_index = header.collect { |col| @csv_cols.index(col.downcase) || @csv_cols.size }
      collection.collect { |array| pri_decode_object(value_index.collect { |i| array[i] }) }
    end
  end
end
