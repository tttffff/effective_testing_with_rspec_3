require_relative "../../app/api"
require "rack/test"

module ExpenseTracker
  RSpec.describe API do
    include Rack::Test::Methods

    def app = API.new(ledger: ledger)

    def json_parsed_includes(hash)
      parsed = JSON.parse(last_response.body)
      expect(parsed).to include(hash)
    end

    def xml_parsed_includes(hash)
      parsed = Ox.load(last_response.body, mode: :hash, symbolize_keys: false)
      expect(parsed).to include(hash.transform_values(&:to_s))
    end

    def status_is(status)
      expect(last_response.status).to eq(status)
    end

    def response_body_without_whitespace
      last_response.body.delete(" \t\r\n")
    end

    let(:ledger) { instance_double("ExpenseTracker::Ledger") }

    describe "POST /expenses" do
      context "when the header specifies JSON" do
        before { header "Content-Type", "application/json" }

        context "when valid JSON is submitted" do
          before do
            allow(ledger).to receive(:record)
              .with({"some" => "data"})
              .and_return(ledger_result)
          end

          let(:payload) { "{\"some\":\"data\"}" }

          context "when the expense is successfully recorded" do
            let(:ledger_result) { RecordResult.new(true, 417, nil) }

            it "returns the expense id" do
              post "/expenses", payload
              json_parsed_includes("expense_id" => 417)
            end

            it "responds with a 200 (OK)" do
              post "/expenses", payload
              status_is 200
            end
          end

          context "when the expense fails validation" do
            let(:ledger_result) { RecordResult.new(false, 417, "Expense incomplete") }

            it "returns an error message" do
              post "/expenses", payload
              json_parsed_includes("error" => "Expense incomplete")
            end

            it "responds with a 422 (Unprocessable entity)" do
              post "/expenses", payload
              status_is 422
            end
          end
        end

        context "when invalid JSON is submitted" do
          let(:payload) { "invalid JSON" }

          it "returns an error message" do
            post "/expenses", payload
            json_parsed_includes("error" => "Invalid JSON")
          end

          it "responds with a 422 (Unprocessable entity)" do
            post "/expenses", payload
            status_is 422
          end
        end
      end

      context "when the header specifies XML" do
        before { header "Content-Type", "application/xml" }

        context "when valid XML is submitted" do
          before do
            allow(ledger).to receive(:record)
              .with({"some" => "data"})
              .and_return(ledger_result)
          end

          let(:payload) { "<some>data</some>" }

          context "when the expense is successfully recorded" do
            let(:ledger_result) { RecordResult.new(true, 417, nil) }

            it "returns the expense id" do
              post "/expenses", payload
              xml_parsed_includes("expense_id" => "417")
            end

            it "responds with a 200 (OK)" do
              post "/expenses", payload
              status_is 200
            end
          end

          context "when the expense fails validation" do
            let(:ledger_result) { RecordResult.new(false, 417, "Expense incomplete") }

            it "returns an error message" do
              post "/expenses", payload
              xml_parsed_includes("error" => "Expense incomplete")
            end

            it "responds with a 422 (Unprocessable entity)" do
              post "/expenses", payload
              status_is 422
            end
          end
        end

        context "when invalid XML is submitted" do
          let(:payload) { "invalid XML" }

          it "returns an error message" do
            post "/expenses", payload
            xml_parsed_includes("error" => "Invalid XML")
          end

          it "responds with a 422 (Unprocessable entity)" do
            post "/expenses", payload
            status_is 422
          end
        end
      end

      context "when the header sepcifises an unused content type" do
        before { header "Content-Type", "text/plain" }

        it "returns an error message" do
          post "/expenses", "some data"
          expect(last_response.body).to eq("Error: Unrecognised data format")
        end

        it "responds with a 422 (Unprocessable entity)" do
          post "/expenses", "some data"
          status_is 422
        end
      end

      context "when the header does not specify a header type" do
        it "returns an error message" do
          post "/expenses", "some data"
          expect(last_response.body).to eq("Error: Unrecognised data format")
        end

        it "responds with a 422 (Unprocessable entity)" do
          post "/expenses", "some data"
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

      context "when the header specifies JSON" do
        before { header "Accept", "application/json" }

        context "when expenses exist on a given date" do
          let(:ledger_result) { [{ex: 42}, {ex: 98}] }

          it "returns the expense records as JSON" do
            get "/expenses/#{date}"
            expect(last_response.body).to eq(ledger_result.to_json)
          end

          it "responds with a 200 (OK)" do
            get "/expenses/#{date}"
            status_is 200
          end
        end

        context "when there are no expensed on the given date" do
          let(:ledger_result) { [] }

          it "returns an empty array as JSON" do
            get "/expenses/#{date}"
            expect(last_response.body).to eq([].to_json)
          end

          it "responds with a 200 (OK)" do
            get "/expenses/#{date}"
            status_is 200
          end
        end
      end

      context "when the header specifies XML" do
        before { header "Accept", "application/xml" }

        context "when expenses exist on a given date" do
          let(:ledger_result) { [{ex: 42}, {ex: 98}] }

          it "returns the expense records as XML" do
            get "/expenses/#{date}"
            expect(response_body_without_whitespace).to eq("<items><item><ex>42</ex></item><item><ex>98</ex></item></items>")
          end

          it "responds with a 200 (OK)" do
            get "/expenses/#{date}"
            status_is 200
          end
        end

        context "when there are no expenses on the given date" do
          let(:ledger_result) { [] }

          it "returns an empty XML tag" do
            get "/expenses/#{date}"
            expect(response_body_without_whitespace).to eq "<items/>"
          end

          it "responds with a 200 (OK)" do
            get "/expenses/#{date}"
            status_is 200
          end
        end
      end
    end
  end
end
