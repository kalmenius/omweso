describe "Omweso" do
	context "should handle info requests" do
		include_examples "a JSON endpoint", 200, lambda { get '/info' }

		it "with the Sinatra environment" do
			expect(@json["environment"]).to eq "test"
		end

		it "with a name from the config file" do
			expect(@json["name"]).to eq "omweso-test"
		end

		it "with the database version" do
			expect(@json["database"]).to start_with "PostgreSQL 11.4"
		end

		context "with information about the AMQP broker" do
			before do
				@amqp = @json["amqp"]
			end

			it "including the product" do
				expect(@amqp["product"]).to eq "RabbitMQ"
			end

			it "including the status" do
				expect(@amqp["status"]).to eq "open"
			end

			it "including the version" do
				expect(@amqp["version"]).to eq "3.7.17"
			end
		end
	end

	context "should handle bad routes" do
		include_examples "a JSON endpoint", 404, lambda { get '/bad-route?foo=bar' }

		it "with some custom error text" do
			expect(@json["error"]).to eq "Route not found: /bad-route?foo=bar"
		end
	end

	context "should handle uncaught exceptions" do
		include_examples "a JSON endpoint", 500, lambda { get '/error' }

		it "with some exception information" do
			expect(@json["error"]).to eq "#<RuntimeError: xyzzy>"
		end
	end
end