# frozen_string_literal: true

require 'pg_random_id'

Sequel.migration do
	up do
		create_random_id_functions
	end

	down do
		drop_random_id_functions
	end
end
