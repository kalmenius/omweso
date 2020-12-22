# frozen_string_literal: true

require 'pg_random_id'

Sequel.migration do
  up do
    create_table :games do
      primary_key :id, type: :bigserial
      Time :created_at, index: true, null: false
      Time :updated_at, index: true, null: false
      TrueClass :public, index: true, null: false, default: false
    end

    random_str_id :games
  end

  down do
    drop_table :games
  end
end
