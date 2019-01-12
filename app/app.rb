require 'sinatra'
require 'sinatra/config_file'
require 'sinatra/json'

config_file '../config/settings.yml'

# Adjust global Sinatra settings.
configure do
	set :show_exceptions, false
	set :raise_errors, false
end

# Adjust test-environment-only settings.
configure :test do
	get '/error' do
		raise "xyzzy"
	end
end

# JSON-ify all responses.
after do
	body json body
end

# Handle bad routes nicely.
not_found do
	{error: "Route not found: #{request.fullpath}"}
end

# Handle uncaught exceptions nicely.
error do
	{error: env['sinatra.error'].inspect}
end

# An endpoint to inspect application state externally.
get '/info' do
	{
		environment: Sinatra::Application.environment,
		sha: ENV['HEROKU_SLUG_COMMIT']
	}
end