require "bundler/setup"
Bundler.require
require "dalli"
require "json"
require "yaml"
require_relative "maruku_helpers"
require_relative "moments"

Moments.run!
