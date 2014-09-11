require "bundler/setup"
Bundler.require
require_relative "./instants"
require 'dalli'

Instants.run!
