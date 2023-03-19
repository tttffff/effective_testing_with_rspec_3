require "ox"
require_relative "base_formatter"

module ExpenseTracker
  class XMLFormatter < BaseFormatter
    def read(request)
      Ox.load(request.body.read, mode: :hash, symbolize_keys: false)
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
  end
end
