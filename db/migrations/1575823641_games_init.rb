Sequel.migration do
	change do
		create_table :games do
			primary_key :id, type: :bigserial, unique: true
			String :name
		end

		random_str_id :games
	end
end
