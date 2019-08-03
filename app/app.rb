require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/custom_logger'
require 'sinatra/json'
require 'ougai'
require 'rack-request-id'
require 'request_store'
require 'sequel'
require 'bunny'

config_file File.expand_path('../config/settings.yml', __dir__)

# An alias for request-scoped data storage.
def rq
	RequestStore.store
end

# Adjust global Sinatra settings.
configure do
	disable :dump_errors
	disable :logging
	disable :raise_errors
	disable :show_exceptions

	use RequestStore::Middleware
	use Rack::RequestId, storage: RequestStore

	logger = Ougai::Logger.new(STDOUT)
	logger.level = settings.log_level
	logger.formatter = Ougai::Formatters::Readable.new if settings.pretty_logs
	logger.before_log = lambda { |data| data.merge!(rq) }
	logger.with_fields = {
		environment: Sinatra::Application.environment,
		name: settings.name
	}
	set :logger, logger

	DB = Sequel.connect(production? ? ENV['DATABASE_URL'] : settings.database, logger: logger.child(logger: 'sequel'))
	AMQP = Bunny.new(production? ? ENV['CLOUDAMQP_URL'] : nil, {logger: logger.child(logger: 'bunny')})
	AMQP.start
end

# Adjust test-environment-only settings.
configure :test do
	get '/error' do
		raise "xyzzy"
	end
end

# Monkey-patching Ougai for more sensible log levels.
module Ougai
	module Formatters::ForJson
		def to_level(severity)
			severity
		end
	end
end

# Store some request-scoped information and log.
before do
	rq[:request_start] ||= Time.now
	rq[:path] ||= request.fullpath
	rq[:verb] ||= request.request_method
	rq[:thread_id] = Thread.current.object_id.to_s(36)

	logger.info "#{rq[:verb]} '#{rq[:path]}' request received"
end

# JSON-ify all responses and log.
after do
	rq[:request_stop] ||= Time.now
	rq[:request_duration] ||= rq[:request_stop] - rq[:request_start]
	rq[:status] = response.status

	body json body

	logger.info "#{rq[:verb]} '#{rq[:path]}' responded with #{rq[:status]} in #{rq[:request_duration]} seconds"
end

# Handle bad routes nicely.
not_found do
	{error: "Route not found: #{rq[:path]}"}
end

# Handle uncaught errors nicely.
error do
	description = env['sinatra.error'].inspect
	logger.error "Caught error during #{rq[:verb]} '#{rq[:path]}': #{description}", env['sinatra.error']
	{error: description}
end

# An endpoint to inspect application state externally.
get '/info' do
	{
		amqp: AMQP.server_properties.merge(status: AMQP.status),
		database: DB['SELECT version()'].first[:version],
		environment: Sinatra::Application.environment,
		name: settings.name,
		sha: ENV['HEROKU_SLUG_COMMIT']
	}
end