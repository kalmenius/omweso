# frozen_string_literal: true

describe "Omweso" do
  context "should handle /info requests" do
    include_examples "a JSON endpoint", -> { get "/info" }

    it "with the Sinatra environment" do
      expect(json[:environment]).to eq "test"
    end

    it "with a name from the config file" do
      expect(json[:name]).to eq "omweso-test"
    end

    it "with the database version" do
      expect(json[:database]).to start_with "PostgreSQL 13.3"
    end

    context "with information about the AMQP broker" do
      let(:amqp) { json[:amqp] }

      it "including the product" do
        expect(amqp[:product]).to eq "RabbitMQ"
      end

      it "including the status" do
        expect(amqp[:status]).to eq "open"
      end

      it "including the version" do
        expect(amqp[:version]).to start_with "3."
      end
    end
  end

  context "should handle bad routes" do
    include_examples "a JSON endpoint", 404, -> { get "/bad-route?foo=bar" }

    it "with some custom error text" do
      expect(json[:error]).to eq "Route not found: GET '/bad-route?foo=bar'"
    end
  end

  context "should handle uncaught exceptions" do
    include_examples "a JSON endpoint", 500, -> { get "/error" }

    it "with some exception information" do
      expect(json[:error]).to eq "#<RuntimeError: xyzzy>"
    end
  end

  context "should parse request bodies into JSON" do
    context "returning an error response when invalid" do
      include_examples "a JSON endpoint", 400, -> { post "/body", "{]" }

      it "with some exception information" do
        expect(json[:error]).to eq "#<BadRequestBody: 809: unexpected token at '{]'>"
      end
    end

    [["GET requests", -> { get "/body" }, {}],
      ["POST requests using an empty body", -> { post "/body" }, {}],
      ["POST requests using a body of {}", -> { post "/body", "{}" }, {}],
      ["POST requests using a body of []", -> { post "/body", "[]" }, []],
      ['POST requests using a body of {"foo":"bar"}', -> { post "/body", '{"foo":"bar"}' }, {foo: "bar"}],
      ['POST requests using a body of {"foo":null}', -> { post "/body", '{"foo":null}' }, {foo: nil}]]
      .each do |context, block, expected|
      context "when making #{context}" do
        include_examples "a JSON endpoint", block

        it "with the same body" do
          expect(json).to eq expected
        end
      end
    end
  end

  context "should use standard log levels in structured logs" do
    let(:buffer) { StringIO.new }
    let(:logger) { Ougai::Logger.new(buffer, level: :trace) }

    %i[trace debug info warn error fatal].each do |level|
      log_level = level.to_s.upcase

      it "for level #{log_level}" do
        logger.send level, "foobar"
        expect(JSON.parse(buffer.string)["level"]).to eq log_level
      end
    end
  end
end
