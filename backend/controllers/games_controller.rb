# frozen_string_literal: true

require_relative "../models/game"

# Retrieves the N most recently created public games still needing another player.
get "/games" do
  limit = param :limit, Integer, within: 1..100, default: 10
  Game.where(:public).reverse(:created_at).limit(limit)
end

# Creates a new game, admitting only the key 'public' from the request body.
post "/games" do
  [201, Game.create(@request_body.slice(:public))]
end

# Retrieves the game with the given ID.
get "/games/:id" do |id|
  Game[id]
end
