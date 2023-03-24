require_relative "../config/sequel"

RecordResult = Struct.new(:success?, :expense_id, :error_message) # TODO: Dont like this here

class Ledger
  REQUIRED_KEYS = %w[payee amount date]

  def record(expense)
    missing_keys = REQUIRED_KEYS - expense.keys
    unless missing_keys.empty?
      return RecordResult.new(false, nil, "Invalid expense: missing key[s]: #{missing_keys.join(", ")}")
    end
    DB[:expenses].insert(expense)
    id = DB[:expenses].max(:id)
    RecordResult.new(true, id, nil)
  end

  def expenses_on(date)
    DB[:expenses].where(date: date).all
  end
end
