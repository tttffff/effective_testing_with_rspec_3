module ExpenseTracker
  class InvalidDataError < StandardError; end

  class BaseFormatter
    def read(request)
      raise NotImplementedError, "Implement this method in a subclass"
    end

    def write(response)
      raise NotImplementedError, "Implement this method in a subclass"
    end
  end
end
