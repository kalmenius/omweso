# TODO
class Game < Sequel::Model
	def self.get_or_raise(id)
		Game[id] || (raise NotFound, id)
	end

	# TODO
	class NotFound < StandardError
		def initialize(id)
			super "Game #{id} not found!"
		end

		def http_status
			404
		end
	end
end