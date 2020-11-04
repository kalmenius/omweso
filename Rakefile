# frozen_string_literal: true

require 'rake'
require 'rspec/core/rake_task'
require 'sequel/rake'

RSpec::Core::RakeTask.new(:spec)
task default: :spec

Sequel::Rake.load!
