require "zeitwerk"

# For autoloading
loader = Zeitwerk::Loader.new
loader.push_dir("app")
loader.inflector.inflect(
  "api" => "API",
  "json_adapter" => "JSONAdapter",
  "xml_adapter" => "XMLAdapter"
)

# For reloading
if ENV["RACK_ENV"] == "development"
  require "filewatcher" # Seems weird to require it when not needed, equally weird not at top of file
  loader.enable_reloading
  filewatcher = Filewatcher.new('app/')
  Thread.new(filewatcher) { _1.watch { loader.reload } }
end

loader.setup # Ready!
