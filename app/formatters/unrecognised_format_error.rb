module Formatters
  class UnrecognisedFormatError < StandardError
    def initialize(accepted_formats:)
      options_text = accepted_formats.join(" or ")
      super("Error: Unrecognised data format\nPlease set your Accept or Content-Type header to #{options_text}")
    end
  end
end
