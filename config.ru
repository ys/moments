require "bundler/setup"
Bundler.require
require_relative "./moments"
require 'dalli'

Moments.run!
