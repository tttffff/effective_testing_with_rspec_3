# Simple factory method to return the correct formatter adapter

module Formatters
  class Factory
    private_class_method :new # Prevents instantiation as it's never needed

    def self.get_formatter(format)
      case format
      when "application/json"
        Adapters::JSONAdapter.new
      when "application/xml"
        Adapters::XMLAdapter.new
      else
        raise UnrecognisedFormatError.new("Error: Unrecognised data format")
      end
    end
  end
end
