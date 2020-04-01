require './app/models/game'

get '/games' do
	Game.all
end

post '/games' do
	[201, Game.create(@request_body)]
end

get '/games/:id' do |id|
	logger.info request.path_info
	Game.get_or_raise id
end