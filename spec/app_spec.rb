describe "Omweso" do
	after do
		expect(last_response.content_type).to eq("application/json")
	end
	
	context "should handle info requests" do
		before do
			get '/info'
			@json = JSON.parse(last_response.body)
		end
		
		it "with HTTP 200" do
			expect(last_response.status).to eq(200)
		end
		
		it "with the Sinatra environment" do
			expect(@json["environment"]).to eq("test")
		end
	end
	
	context "should handle bad routes" do
		before do
			get '/bad-route?foo=bar'
			@json = JSON.parse(last_response.body)
		end
		
		it "with HTTP 404" do
			expect(last_response.status).to eq(404)
		end
		
		it "with some custom error text" do
			expect(@json["error"]).to eq("Route not found: /bad-route?foo=bar")
		end
	end
	
	context "should handle uncaught exceptions" do
		before do
			get '/error'
			@json = JSON.parse(last_response.body)
		end
		
		it "with HTTP 500" do
			expect(last_response.status).to eq(500)
		end
		
		it "with some exception information" do
			expect(@json["error"]).to eq("#<RuntimeError: xyzzy>")
		end
	end
end