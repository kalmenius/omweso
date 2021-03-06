# frozen_string_literal: true

require "sinatra"
require "sinatra/config_file"
require "sinatra/custom_logger"
require "sinatra/multi_route"
require "sinatra/param"
require "sinatra/json"
require "ougai"
require "rack-request-id"
require "request_store"
require "sequel"
require "bunny"

module Ougai
  module Formatters
    # Monkey-patching Ougai for more sensible log levels.
    module ForJson
      def to_level(severity) = severity
    end
  end
end

module Sinatra
  module Param
    # Monkey-patching sinatra-param to enforce HTTP 400 on thrown parameter errors.
    class InvalidParameterError
      def http_status = 400
    end
  end
end

# An alias for request-scoped data storage.
def rq = RequestStore.store

# Adjust global Sinatra settings.
config_file File.expand_path("../config/settings.yml", __dir__)
helpers Sinatra::Param
disable :dump_errors, :logging, :raise_errors, :show_exceptions
enable :raise_sinatra_param_exceptions

use RequestStore::Middleware
use Rack::RequestId, storage: RequestStore

logger = Ougai::Logger.new $stdout
logger.level = settings.log_level
logger.formatter = Ougai::Formatters::Readable.new if settings.pretty_logs
logger.before_log = ->(data) { data.merge! rq }
logger.with_fields = {
  environment: Sinatra::Application.environment,
  name: settings.name
}
set :logger, logger

logger.info "Establishing database connection..."
DB = Sequel.connect(ENV["DATABASE_URL"] || settings.database, logger: logger.child({logger: "sequel"}))
Sequel::Model.plugin :json_serializer
Sequel.default_timezone = :utc

logger.info "Establishing AMQP connection..."
AMQP = Bunny.new(ENV["CLOUDAMQP_URL"] || nil, logger: logger.child({logger: "bunny"}))
AMQP.start

# Finally, we register all controller classes.
Dir.glob("./backend/controllers/*.rb").each do |file|
  logger.info "Registering controller #{File.basename(file)}"
  require file
end

# Establish some endpoints only needed by the specs.
configure :test do
  get "/error" do
    raise "xyzzy"
  end

  route :get, :post, "/body" do
    @request_body
  end
end

# An error for request bodies that are not valid JSON.
class BadRequestBody < StandardError
  def http_status = 400
end

# Store some request-scoped information, store the request body (complaining if not JSON), and log.
before do
  rq[:request_start] ||= Time.now
  rq[:path] ||= request.fullpath
  rq[:verb] ||= request.request_method
  rq[:thread_id] = Thread.current.object_id.to_s(36)

  request.body.rewind
  begin
    @request_body = request.body.read.then { |body| body.empty? ? {} : JSON.parse(body, symbolize_names: true) }
  rescue JSON::JSONError => e
    raise BadRequestBody, e
  end

  logger.info "#{rq[:verb]} '#{rq[:path]}' request received with body #{@request_body}"
end

# JSON-ify all responses and log.
after do
  rq[:request_stop] ||= Time.now
  rq[:request_duration] ||= rq[:request_stop] - rq[:request_start]
  rq[:status] = response.status

  body json body

  logger.info "#{rq[:verb]} '#{rq[:path]}' responded with #{rq[:status]} in #{rq[:request_duration]} seconds"
end

# Handle bad routes and uncaught errors nicely.
error 400..599 do
  err = env["sinatra.error"]
  route_description = "#{rq[:verb]} '#{rq[:path]}'"

  if err.is_a? Sinatra::NotFound
    {error: "Route not found: #{route_description}"}
  else
    description = err.inspect
    logger.error "Caught error during #{route_description}: #{description}", err
    {error: description}
  end
end

# An endpoint to inspect application state externally.
get "/info" do
  {
    amqp: AMQP.server_properties.merge(status: AMQP.status),
    database: DB["SELECT version()"].first[:version],
    environment: Sinatra::Application.environment,
    name: settings.name,
    sha: ENV["HEROKU_SLUG_COMMIT"] || `git rev-parse HEAD`.strip
  }
end
