require "bundler/setup"
Bundler.require
require_relative "./moments"
require 'dalli'
require_relative "maruku_helpers"

Moments.run!
