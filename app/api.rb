require "sinatra/base"
require "json"
require_relative "ledger"

module ExpenseTracker
  class API < Sinatra::Base
    attr_reader :ledger

    def initialize(ledger: Ledger.new)
      @ledger = ledger
      super()
    end

    post "/expenses" do
      expense = JSON.parse(request.body.read)
      result = ledger.record(expense)
      process_result(result, :expense_id)
    end

    get "/expenses/:date" do
      date = params["date"]
      result = ledger.expenses_on(date)
      process_result(result, :expenses)
    end

    private

    def process_result(result, target)
      return JSON.generate(target => result.send(target)) if result.success?
      status 422
      JSON.generate(error: result.error_message)
    end
  end
end
