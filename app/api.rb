require "sinatra/base"
require_relative "ledger"
require_relative "formatters/formatter_factory"

module ExpenseTracker
  class API < Sinatra::Base
    attr_reader :ledger

    def initialize(ledger: Ledger.new)
      @ledger = ledger
      super()
    end

    post "/expenses" do
      formatter = FormatterFactory.get_formatter(request.env["CONTENT_TYPE"])
      expense = formatter.read(request)
      result = ledger.record(expense)
      return formatter.write(expense_id: result.expense_id) if result.success?
      status 422
      formatter.write(error: result.error_message)
    rescue UnrecognisedDataFormatError, InvalidDataError => e
      status 422
      return e.message
    end

    get "/expenses/:date" do
      formatter = FormatterFactory.get_formatter(request.env["HTTP_ACCEPT"])
      date = params["date"]
      result = ledger.expenses_on(date)
      formatter.write(result)
    rescue UnrecognisedDataFormatError => e
      status 406
      return e.message
    end
  end
end
