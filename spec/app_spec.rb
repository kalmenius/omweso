describe "Omweso" do
	it "should produce a known JSON on all routes" do
		get '/'
		expect(last_response).to be_ok
		expect(last_response.body).to eq("{\"meep\":\"moop\"}")
	end
	
	it "should not fail this test" do
		# fail
	end
end