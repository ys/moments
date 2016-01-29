require "bundler/setup"
Bundler.require
require "dalli"
require "json"
require "yaml"

module Setup
  def self.require_glob(path)
		Dir[path].each {|file|
			require file
		}
	end

  def self.require!(globs)
		Array(globs).each do |f|
      require_glob("./#{f}.rb")
		end
	end
end

Setup.require! %w{config/**/*}
require_relative "config/maruku_helpers"
require_relative "lib/dropbox_base"
require_relative "lib/dropbox_file"
require_relative "lib/dropbox_folder"
require_relative "lib/endpoints/base"
Setup.require! %w{lib/**/*}

use Sinatra::Router do
  mount Endpoints::Pictures
  mount Endpoints::Posts
  mount Endpoints::Root
  mount Endpoints::CatchAll
end
run Sinatra::Application
