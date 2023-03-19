# Simple factory method to return the correct formatter adapter
require_relative "json_formatter"
require_relative "xml_formatter"

module ExpenseTracker
  class UnrecognisedDataFormatError < StandardError; end

  class FormatterFactory
    private_class_method :new # Prevents instantiation as it's never needed

    def self.get_formatter(format)
      case format
      when "application/json"
        JSONFormatter.new
      when "application/xml"
        XMLFormatter.new
      else
        raise UnrecognisedDataFormatError.new("Error: Unrecognised data format")
      end
    end
  end
end
