# frozen_string_literal: true

require "rake"
require "rspec/core/rake_task"
require "sequel/rake"
require "standard/rake"

RSpec::Core::RakeTask.new(:spec)
task default: :spec

Sequel::Rake.load!

task :cleanup, [:age] do |_, args|
  args.with_defaults(age: 86_400)

  cutoff = (Time.now - args.age.to_i).utc
  puts "Game cleanup START -- #{cutoff}"

  Sequel.connect(Sequel::Rake.get(:connection))
  require_relative "backend/models/game"

  num_deleted = Game.where { updated_at < cutoff }.delete
  puts "Game cleanup STOP --- #{cutoff} (#{num_deleted} were deleted)"
end
