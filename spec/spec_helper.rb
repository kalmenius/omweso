require 'rack/test'
require 'rspec'

ENV['RACK_ENV'] = 'test'

require_relative '../app/app.rb'

module RSpecMixin
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end
end

shared_examples_for 'a JSON endpoint' do |code = 200, block|
	before do
		instance_exec(&block)
		@json = JSON.parse last_response.body
	end

	it "with HTTP #{code}" do
		expect(last_response.status).to eq code
	end

	it 'with JSON content' do
		expect(last_response.content_type).to eq 'application/json'
	end

	context 'with a request ID header' do
		def request_id
			last_response.headers['x-request-id']
		end

		before do
			@request_id = request_id
		end

		it 'that is present' do
			expect(@request_id).not_to be_nil
		end

		it 'that is distinct each time' do
			instance_exec(&block)
			expect(request_id).not_to eq @request_id
		end
	end
end

RSpec.configure do |config|
	config.include RSpecMixin

	config.expect_with :rspec do |expectations|
		expectations.include_chain_clauses_in_custom_matcher_descriptions = true
	end

	config.mock_with :rspec do |mocks|
		mocks.verify_partial_doubles = true
	end

	config.shared_context_metadata_behavior = :apply_to_host_groups
end