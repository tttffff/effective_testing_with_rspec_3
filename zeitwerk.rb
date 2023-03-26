require "zeitwerk"

# For autoloading
loader = Zeitwerk::Loader.new
loader.push_dir("app")
loader.inflector.inflect(
  "api" => "API",
  "json_adapter" => "JSONAdapter",
  "xml_adapter" => "XMLAdapter"
)

# For reloading, will not work on API unless you create a new instance after reload
if ENV["RACK_ENV"] == "development"
  require "filewatcher" # Seems weird to go here, but why require it when not needed.
  loader.enable_reloading
  filewatcher = Filewatcher.new('app/')
  Thread.new(filewatcher) { _1.watch { loader.reload } }
end

loader.setup # Ready!
