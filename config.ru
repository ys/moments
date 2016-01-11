require "bundler/setup"
Bundler.require
require "dalli"
require "json"
require "yaml"
require_relative "maruku_helpers"
require_relative "lib/dropbox_base"
require_relative "lib/dropbox_file"
require_relative "lib/dropbox_folder"
require_relative "lib/index"
require_relative "lib/moments"
require_relative "lib/posts"
require_relative "lib/moment"
require_relative "lib/post"
require_relative "lib/picture"
require_relative "moments_app"

MomentsApp.run!
