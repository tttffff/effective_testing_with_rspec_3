RSpec.configure do |config|
  config.before(:suite) do
    Sequel.extension :migration
    Sequel::Migrator.run(DB, "db/migrations")
    DB[:expenses].truncate
  end

  config.around(:each, :db) do |example|
    DB.transaction(rollback: :always) { example.run }
  end
end
