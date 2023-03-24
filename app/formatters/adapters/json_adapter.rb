require "json"

module Formatters
  module Adapters
    class JSONAdapter < Base
      def read(request)
        JSON.parse(request.body.read)
      rescue JSON::ParserError
        raise InvalidDataError, write(error: "Invalid JSON")
      end

      def write(response) = JSON.generate(response)
    end
  end
end
