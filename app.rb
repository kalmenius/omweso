require 'sinatra'

# Adjust global Sinatra settings.
configure do
	set :show_exceptions, false
end

# JSON-ify all responses.
after do
	content_type :json
	body body.to_json
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
	{environment: Sinatra::Application.environment, sha: env['HEROKU_SLUG_COMMIT']}
end