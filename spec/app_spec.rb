describe "Omweso" do
	it "should respond to info requests" do
		get '/info'
		expect(last_response).to be_ok
		expect(JSON.parse(last_response.body)["environment"]).to eq("test")
	end
	
	it "should handle bad routes nicely" do
		get '/bad-route?foo=bar'
		expect(last_response).to be_not_found
		expect(last_response.body).to eq("{\"error\":\"Route not found: /bad-route?foo=bar\"}")
	end
end