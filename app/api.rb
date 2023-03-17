require "sinatra/base"
require "json"

module ExpenseTracker
  class API < Sinatra::Base
    post "/expenses" do
      {expense_id: 42}.to_json
    end

    get "/expenses/:date" do
      JSON.generate([])
    end
  end
end
