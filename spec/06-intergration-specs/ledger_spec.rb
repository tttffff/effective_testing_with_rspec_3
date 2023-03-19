require_relative "../../app/ledger"

module ExpenseTracker
  RSpec.describe Ledger, :aggregate_failures, :db do
    let(:ledger) { Ledger.new }
    let(:expense) do
      {
        "payee" => "Starbucks",
        "amount" => 5.75,
        "date" => "2017-06-10"
      }
    end

    describe "#record" do
      context "with a valid expense" do
        it "successfully saves the expense in the DB" do
          result = ledger.record(expense)

          expect(result).to be_success
          expect(DB[:expenses].all).to match [a_hash_including(
            id: result.expense_id,
            payee: "Starbucks",
            amount: 5.75,
            date: Date.iso8601("2017-06-10")
          )]
        end
      end

      shared_examples "with missing field" do |field|
        it "rejects the expense as invalid" do
          expense.delete(field)
          result = ledger.record(expense)

          expect(result).not_to be_success
          expect(result.expense_id).to be_nil
          expect(result.error_message).to include("Invalid expense: missing key[s]: #{field}")
          expect(DB[:expenses].count).to eq(0)
        end
      end

      context "when the expense lacks a payee" do
        it_behaves_like "with missing field", "payee"
      end

      context "when the expense lacks an amount" do
        it_behaves_like "with missing field", "amount"
      end

      context "when the expense lacks a date" do
        it_behaves_like "with missing field", "date"
      end
    end

    describe "#expenses_on" do
      it "returns all expenses on the given date" do
        result_1 = ledger.record(expense.merge("date" => "2017-06-10"))
        result_2 = ledger.record(expense.merge("date" => "2017-06-10"))
        result_3 = ledger.record(expense.merge("date" => "2017-06-11"))

        expect(ledger.expenses_on("2017-06-10")).to contain_exactly(
          a_hash_including(id: result_1.expense_id),
          a_hash_including(id: result_2.expense_id)
        )
      end

      it "returns an empty array when there are no expenses on the given date" do
        expect(ledger.expenses_on("2017-06-10")).to eq([])
      end
    end
  end
end
