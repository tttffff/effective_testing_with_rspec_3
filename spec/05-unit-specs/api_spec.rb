require_relative "../../app/api"
require "rack/test"

module ExpenseTracker
  RSpec.describe API do
    include Rack::Test::Methods

    def app = API.new(ledger: ledger)

    def parsed_includes(hash)
      parsed = JSON.parse(last_response.body)
      expect(parsed).to include(hash)
    end

    def status_is(status)
      expect(last_response.status).to eq(status)
    end

    let(:ledger) { instance_double("ExpenseTracker::Ledger") }

    describe 'POST /expenses' do
      before do
        allow(ledger).to receive(:record)
          .with(expense)
          .and_return(ledger_result)
      end

      context "when the expense is successfully recorded" do
        let(:expense) { { "some" => "data" } }
        let(:ledger_result) { RecordResult.new(true, 417, nil) }

        it "returns the expense id" do
          post "/expenses", JSON.generate(expense)
          parsed_includes("expense_id" => 417)
        end

        it "responds with a 200 (OK)" do
          post "/expenses", JSON.generate(expense)
          status_is 200
        end
      end

      context "when the expense fails validation" do
        let(:expense) { { "some" => "data" } }
        let(:ledger_result) { RecordResult.new(false, 417, "Expense incomplete") }

        it "returns an error message" do
          post "/expenses", JSON.generate(expense)
          parsed_includes("error" => "Expense incomplete")
        end

        it "responds with a 422 (Unprocessable entity)" do
          post "/expenses", JSON.generate(expense)
          status_is 422
        end
      end
    end

    describe "GET /expenses/:date" do
      let(:date) { "2023-01-01" }

      before do
        allow(ledger).to receive(:expenses_on)
          .with(date)
          .and_return(ledger_result)
      end

      context "when the request is succesfull" do
        context "when expenses exist on a given date" do
          let(:expenses) { [{ex: 42}, {ex: 98}].to_json }
          let(:ledger_result) { RecordsResult.new(true, expenses, nil) }

          it "returns the expense records as JSON" do
            get "/expenses/#{date}"
            parsed_includes("expenses" => expenses)
          end

          it "responds with a 200 (OK)" do
            get "/expenses/#{date}"
            status_is 200
          end
        end

        context "when there are no expensed on the given date" do
          let(:ledger_result) { RecordsResult.new(true, [].to_json, nil) }

          it "returns an empty array as JSON" do
            get "/expenses/#{date}"
            parsed_includes("expenses" => [].to_json)
          end

          it "responds with a 200 (OK)" do
            get "/expenses/#{date}"
            status_is 200
          end
        end
      end

      context "when the request is unsussesfull" do
        let(:ledger_result) { RecordResult.new(false, nil, "Database Lookup Error") }

        it "returns an error message" do
          get "/expenses/#{date}"
          parsed_includes("error" => "Database Lookup Error")
        end

        it "responds with a 422 (Unprocessable entity)" do
          get "/expenses/#{date}"
          status_is 422
        end
      end
    end
  end
end