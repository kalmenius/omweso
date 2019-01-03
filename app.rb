require 'sinatra'

after do
	content_type :json
	body body.to_json
end

get '*' do
	{:meep => "moop"}
end