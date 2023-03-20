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

    def parsed_includes(type, hash)
      case type
      when "JSON"
        json_parsed_includes(hash)
      when "XML"
        xml_parsed_includes(hash)
      end
    end

    def status_is(status)
      expect(last_response.status).to eq(status)
    end

    def response_body_without_whitespace
      last_response.body.delete(" \t\r\n")
    end

    let(:ledger) { instance_double("ExpenseTracker::Ledger") }

    describe "POST /expenses" do
      shared_examples "the data type and format are correct" do |type, data|
        before do
          allow(ledger).to receive(:record)
            .with({"some" => "data"})
            .and_return(ledger_result)
        end

        context "when the expense is successfully recorded" do
          let(:ledger_result) { RecordResult.new(true, 417, nil) }

          it "returns the expense id" do
            post "/expenses", data
            parsed_includes(type, "expense_id" => 417)
          end

          it "responds with a 200 (OK)" do
            post "/expenses", data
            status_is 200
          end
        end

        context "when the expense fails validation" do
          let(:ledger_result) { RecordResult.new(false, 417, "Expense incomplete") }

          it "returns an error message" do
            post "/expenses", data
            parsed_includes(type, "error" => "Expense incomplete")
          end

          it "responds with a 422 (Unprocessable entity)" do
            post "/expenses", data
            status_is 422
          end
        end
      end

      shared_examples "the data format is incorrect" do |type, data|
        it "returns an error message" do
          post "/expenses", data
          parsed_includes(type, "error" => "Invalid #{type}")
        end

        it "responds with a 422 (Unprocessable entity)" do
          post "/expenses", data
          status_is 422
        end
      end

      shared_examples "the data type is incorrect" do
        it "returns an error message" do
          post "/expenses", "some data"
          expect(last_response.body).to eq("Error: Unrecognised data format")
        end

        it "responds with a 422 (Unprocessable entity)" do
          post "/expenses", "some data"
          status_is 422
        end
      end

      context "when the header specifies JSON" do
        before { header "Content-Type", "application/json" }

        context "when valid JSON is submitted" do
          it_behaves_like "the data type and format are correct", "JSON", { "some" => "data" }.to_json
        end

        context "when invalid JSON is submitted" do
          it_behaves_like "the data format is incorrect", "JSON", "invalid JSON"
        end
      end

      context "when the header specifies XML" do
        before { header "Content-Type", "application/xml" }

        context "when valid XML is submitted" do
          it_behaves_like "the data type and format are correct", "XML", "<some>data</some>"
        end

        context "when invalid XML is submitted" do
          it_behaves_like "the data format is incorrect", "XML", "invalid XML"
        end
      end

      context "when the header specifies an unused content type" do
        before { header "Content-Type", "text/plain" }

        it_behaves_like "the data type is incorrect"
      end

      context "when the header does not specify a header type" do
        it_behaves_like "the data type is incorrect"
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
