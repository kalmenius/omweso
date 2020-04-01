describe 'Games Controller' do
	context 'should handle /games requests' do
		include_examples 'a JSON endpoint', -> { get '/games' }
	end
end