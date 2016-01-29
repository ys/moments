module Endpoints
  class Base < Sinatra::Base

    set :root, File.expand_path("../../../", __FILE__)
    set :views, Proc.new { File.join(root , "views") }

    register Sinatra::Subdomain

    configure :development do
      require "pry"
    end

    configure :production do
      use Rack::SslEnforcer
      ENV["MEMCACHE_SERVERS"]  = ENV["MEMCACHIER_SERVERS"] if ENV["MEMCACHIER_SERVERS"]
      ENV["MEMCACHE_USERNAME"] = ENV["MEMCACHIER_USERNAME"] if ENV["MEMCACHIER_USERNAME"]
      ENV["MEMCACHE_PASSWORD"] = ENV["MEMCACHIER_PASSWORD"] if ENV["MEMCACHIER_PASSWORD"]

      set :cache, Dalli::Client.new

      use Rack::Cache,
          verbose:     true,
          metastore:   settings.cache,
          entitystore: settings.cache
    end

    def flush_cache
      halt 401 if ENV["FLUSH_TOKEN"] != params[:t]
      settings.cache.flush
      params[:challenge]
    end

    def authorize!
      return unless password
      return if authorization && password == given_password
      unauthorized!
    end

    def given_password
      user_password.split(/:/, 2)[1]
    end

    def user_password
      authorization.split(" ").last.unpack("m*").first
    end

    def authorization
      env["HTTP_AUTHORIZATION"]
    end

    def password
      if settings.respond_to?("cache")
        settings.cache.get("#{params[:path]}/password")
      else
        fetch_and_cache_password
      end
    end

    def fetch_and_cache_password
      psw = DropboxFile.new("/#{params[:path]}/passwd").content
      if settings.respond_to?("cache")
        settings.cache.set("#{params[:path]}/password", p)
      end
      psw
    rescue DropboxError => e
    end

    def unauthorized!
      headers["Content-Type"] = "text/plain"
      headers["Content-Length"] = "0"
      headers["WWW-Authenticate"] = "Basic realm='Password protected'"
      halt 401
    end
  end
end
