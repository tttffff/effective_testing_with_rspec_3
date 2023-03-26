require "rack/test"
require "json"

RSpec.describe "Expense Tracker API", :db do
  include Rack::Test::Methods

  def app = API.new

  def json_post_expense(expense)
    post "/expenses", JSON.generate(expense)
    expect(last_response.status).to eq(200)

    parsed = JSON.parse(last_response.body)
    expect(parsed).to include("expense_id" => a_kind_of(Integer))
    expense.merge("id" => parsed["expense_id"])
  end

  def xml_post_expense(expense)
    xml = expense.map { |key, value| "<#{key}>#{value}</#{key}>" }.join
    post "/expenses", xml
    expect(last_response.status).to eq(200)

    parsed = Ox.load(last_response.body, mode: :hash, symbolize_keys: false)
    expect(parsed).to include("expense_id" => /\A\d+\z/)
    expense.merge("id" => parsed["expense_id"])
  end

  let(:coffee_payload) { {"payee" => "Starbucks", "amount" => 5.75, "date" => "2017-06-10"} }
  let(:zoo_payload) { {"payee" => "Zoo", "amount" => 15.25, "date" => "2017-06-10"} }
  let(:food_payload) { {"payee" => "Whole Foods", "amount" => 95.20, "date" => "2017-06-11"} }

  context "when JSON is used" do
    it "records submitted expenses and recalls those on the date given" do
      header "Content-Type", "application/json"
      coffee = json_post_expense(coffee_payload)
      zoo = json_post_expense(zoo_payload)
      json_post_expense(food_payload)

      header "Accept", "application/json"
      get "/expenses/2017-06-10"
      expect(last_response.status).to eq(200)
      expenses = JSON.parse(last_response.body)
      expect(expenses).to contain_exactly(coffee, zoo)
    end
  end

  context "when XML is used" do
    it "records submitted expenses and recalls those on the date given" do
      header "Content-Type", "application/xml"
      coffee = xml_post_expense(coffee_payload)
      zoo = xml_post_expense(zoo_payload)
      xml_post_expense(food_payload)

      header "Accept", "application/xml"
      get "/expenses/2017-06-10"
      expect(last_response.status).to eq(200)
      expenses = Ox.load(last_response.body, mode: :hash, symbolize_keys: false)["items"]["item"]
      # The above creates all the values as strings
      expect(expenses).to contain_exactly(coffee.transform_values(&:to_s), zoo.transform_values(&:to_s))
    end
  end
end
