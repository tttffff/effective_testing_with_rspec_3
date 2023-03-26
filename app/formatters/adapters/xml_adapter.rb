require "ox"

# TODO: This class feels messy. Is it worth learning about XML parsing to make it cleaner?

module Formatters
  module Adapters
    class XMLAdapter < Base
      def read(request)
        hash = Ox.load(request.body.read, mode: :hash, symbolize_keys: false)
        hash.transform_values(&method(:string_to_number))
      rescue Ox::ParseError
        raise InvalidDataError, write(error: "Invalid XML")
      end

      def write(response)
        elements = if response.is_a?(Array)
          items = response.flat_map { |item| hash_to_elements(item: item) }
          [items.reduce(Ox::Element.new("items")) { |elm, child| elm << child }]
        else
          hash_to_elements(response)
        end
        doc = elements.reduce(Ox::Document.new) { |doc, elm| doc << elm }
        Ox.dump(doc)
      end

      private

      def hash_to_elements(hash)
        hash.map do |key, value|
          if value.is_a?(Hash)
            hash_to_elements(value).reduce(Ox::Element.new(key)) { |elm, child| elm << child }
          else
            Ox::Element.new(key) << value.to_s
          end
        end
      end

      # Float if it has a decimal point, otherwise Integer
      def string_to_number(str)
        return str unless str[/\A[\d\.]+\z/] # Original if not a number
        str.include?(".") ? str.to_f : str.to_i
      end
    end
  end
end
