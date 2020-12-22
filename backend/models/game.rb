# frozen_string_literal: true

require 'sequel'

# A nice game of Omweso.
class Game < Sequel::Model
  plugin :timestamps, update_on_create: true
  plugin :touch

  def self.[](id)
    super(id) || (raise NotFound, id)
  end

  # An error indicating that the game with the given ID isn't present in the database.
  class NotFound < StandardError
    include HTTP404

    def initialize(id)
      super "Game #{id} not found!"
    end
  end
end
