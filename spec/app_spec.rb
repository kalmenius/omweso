describe "Omweso" do
	context "should handle info requests" do
		include_examples "a JSON endpoint", 200, lambda {get '/info'}

		it "with the Sinatra environment" do
			expect(@json["environment"]).to eq "test"
		end
	end

	context "should handle bad routes" do
		include_examples "a JSON endpoint", 404, lambda {get '/bad-route?foo=bar'}

		it "with some custom error text" do
			expect(@json["error"]).to eq "Route not found: /bad-route?foo=bar"
		end
	end

	context "should handle uncaught exceptions" do
		include_examples "a JSON endpoint", 500, lambda {get '/error'}

		it "with some exception information" do
			expect(@json["error"]).to eq "#<RuntimeError: xyzzy>"
		end
	end
end