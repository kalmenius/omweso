# frozen_string_literal: true

# \ --quiet
$stdout.sync = true
require "bundler/setup"
Bundler.require :default, (ENV["RACK_ENV"] || "development").to_sym
require "./backend/app"
run Sinatra::Application
