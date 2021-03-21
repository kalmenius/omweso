# frozen_string_literal: true

describe "Games Controller" do
  context "should handle GET /games requests" do
    before { Game.dataset.delete }

    shared_examples "a GET /games call" do |code = 200, limit = nil|
      path = "/games"
      path += "?limit=#{limit}" unless limit.nil?

      include_examples "a JSON endpoint", code, -> { get path }
    end

    context "when no games exist" do
      include_examples "a GET /games call"

      it "with an empty array" do
        expect(json).to eq []
      end
    end

    context "when one public game exists" do
      let!(:game) { Game.create public: true }
      include_examples "a GET /games call"

      it "with the single public game" do
        expect(json).to eq [game.for_specs]
      end
    end

    context "when one private game exists" do
      let!(:game) { Game.create }
      include_examples "a GET /games call"

      it "with an empty array" do
        expect(json).to eq []
      end
    end

    context "when fifteen public games exist" do
      let!(:older_games) { Array.new(5) { Game.create public: true } }
      let!(:newer_games) { Array.new(10) { Game.create public: true } }
      include_examples "a GET /games call"

      it "with the newest ten games" do
        expect(json).to eq newer_games.reverse.map(&:for_specs)
      end
    end

    [2, 5, 15].each do |limit|
      surplus = 5

      context "when #{limit + surplus} public games exist and passed ?limit=#{limit}" do
        let!(:older_games) { Array.new(surplus) { Game.create public: true } }
        let!(:newer_games) { Array.new(limit) { Game.create public: true } }
        include_examples "a GET /games call", 200, limit

        it "with the newest #{limit} games" do
          expect(json).to eq newer_games.reverse.map(&:for_specs)
        end
      end
    end

    context "when passed ?limit=foobar" do
      include_examples "a GET /games call", 400, "foobar"

      it "with some exception information" do
        expect(json[:error]).to eq "#<Sinatra::Param::InvalidParameterError: 'foobar' is not a valid Integer>"
      end
    end

    [0, 101, 1000].each do |limit|
      context "when passed ?limit=#{limit}" do
        include_examples "a GET /games call", 400, limit

        it "with some exception information" do
          expect(json[:error]).to eq "#<Sinatra::Param::InvalidParameterError: Parameter must be within 1..100>"
        end
      end
    end
  end

  context "should handle POST /games requests" do
    shared_examples "a POST /games call" do |public = false, body = nil|
      block = -> { post "/games", body&.to_json }
      include_examples "a JSON endpoint", 201, block

      let!(:new_game) { json.to_dot }

      context "with a unique game ID" do
        it "that is present" do
          expect(new_game).to respond_to :id
        end

        it "that is distinct each time" do
          instance_exec(&block)
          expect(last_response_json.to_dot.id).not_to eq new_game.id
        end
      end

      it "with public: #{public}" do
        expect(new_game.public).to eq public
      end

      it "with created_at timestamp" do
        expect(new_game).to respond_to :created_at
      end

      it "with updated_at timestamp" do
        expect(new_game).to respond_to :updated_at
      end

      it "with matching created_at and updated_at timestamps" do
        expect(new_game.updated_at).to eq new_game.created_at
      end

      it "with all fields matching the database" do
        expect(new_game).to eq Game[new_game.id].for_specs
      end
    end

    context "when sending no body" do
      include_examples "a POST /games call"
    end

    context "when sending an unfamiliar key" do
      include_examples "a POST /games call", false, {foo: "bar"}

      it "and ignoring it" do
        expect(new_game).not_to respond_to :foo
      end
    end

    context "when sending an immutable key" do
      include_examples "a POST /games call", false, {id: "foobar"}

      it "and ignoring the passed value for it" do
        expect(new_game.id).not_to eq "foobar"
      end
    end

    [true, false].each do |public|
      context "when sending {public: #{public}}" do
        include_examples "a POST /games call", public, {public: public}
      end
    end
  end

  context "should handle GET /games/:id requests" do
    context "for a valid game ID" do
      let!(:game) { Game.create }
      include_examples "a JSON endpoint", -> { get "/games/#{game.id}" }

      it "with all fields matching the database" do
        expect(json).to eq game.for_specs
      end
    end

    context "for an invalid game ID" do
      include_examples "a JSON endpoint", 404, -> { get "/games/#{bad_id}" }

      let(:bad_id) { SecureRandom.alphanumeric(6) }

      it "with some exception information" do
        expect(json[:error]).to eq "#<Game::NotFound: Game #{bad_id} not found!>"
      end
    end
  end
end
