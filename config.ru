#\ --quiet
$stdout.sync = true
require 'bundler/setup'
Bundler.require :default, (ENV['RACK_ENV'] || 'development').to_sym
require './app/app'
run Sinatra::Application