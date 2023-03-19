require "json"
require_relative "base_formatter"

module ExpenseTracker
  class JSONFormatter < BaseFormatter
    def read(request)
      JSON.parse(request.body.read)
    rescue JSON::ParserError
      raise InvalidDataError, write(error: "Invalid JSON")
    end

    def write(response) = JSON.generate(response)
  end
end
