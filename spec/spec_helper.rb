# frozen_string_literal: true

require "hash_dot"
require "rack/test"
require "rspec"
require "simplecov"
require "stringio"

SimpleCov.start

ENV["RACK_ENV"] = "test"

require_relative "../backend/app"

module RSpecMixin
  include Rack::Test::Methods

  def app = Sinatra::Application
end

module Sequel
  class Model
    def for_specs
      values.transform_values do |value|
        if value.is_a? Time
          value.to_s
        else
          value
        end
      end
    end
  end
end

shared_examples "a JSON endpoint" do |code = 200, block|
  def last_response_json = JSON.parse(last_response.body, symbolize_names: true)

  let!(:json) do
    instance_exec(&block)
    last_response_json
  end

  it "with HTTP #{code}" do
    expect(last_response.status).to eq code
  end

  it "with JSON content" do
    expect(last_response.content_type).to eq "application/json"
  end

  context "with a request ID header" do
    def last_request_id = last_response.headers["x-request-id"]

    let!(:first_request_id) { last_request_id }

    it "that is present" do
      expect(first_request_id).not_to be_nil
    end

    it "that is distinct each time" do
      instance_exec(&block)
      expect(last_request_id).not_to eq first_request_id
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
