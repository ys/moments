require "json"

class Moments < Sinatra::Base

  ENV["MEMCACHE_SERVERS"]  = ENV["MEMCACHIER_SERVERS"] if ENV["MEMCACHIER_SERVERS"]
  ENV["MEMCACHE_USERNAME"] = ENV["MEMCACHIER_USERNAME"] if ENV["MEMCACHIER_USERNAME"]
  ENV["MEMCACHE_PASSWORD"] = ENV["MEMCACHIER_PASSWORD"] if ENV["MEMCACHIER_PASSWORD"]

  set :cache, Dalli::Client.new

  use Rack::Cache,
    verbose:     true,
    metastore:   settings.cache,
    entitystore: settings.cache

  get '/' do
    cache_control :public, max_age: 3600
    moments = dropbox_client.metadata("/")["contents"].sort_by {|e| e["client_mtime"] }
    erb :index, locals: { moments: moments }
  end

  get "/:path" do
    authorize!
    cache_control :public, max_age: 3600
    folder = dropbox_client.metadata("/#{params[:path]}", 25000, true, nil, nil, false, true)
    pictures = folder["contents"].select { |e| e["thumb_exists"] == true && !e["path"].match(/_cover|password/)}
    erb :moment, locals: { pictures: pictures }
  end

  get "/thumbs/*" do
    cache_control :public, max_age: 36000
    t, metadata = dropbox_client.thumbnail_and_metadata("/#{params[:splat].first}", "xl")
    content_type metadata["mime_type"]
    t
  end

  get "/cache/flush" do
    flush_cache
  end

  post "/cache/flush" do
    flush_cache
  end

  def flush_cache
    if ENV["FLUSH_TOKEN"] != params[:t]
      halt 401
    end
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
    settings.cache.get("#{params[:path]}/password") || fetch_and_cache_password
  end

  def fetch_and_cache_password
    puts env.inspect
    dropbox_client.get_file("/#{params[:path]}/password.txt").strip
      .tap {|p| settings.cache.set("#{params[:path]}/password", p) }
  rescue DropboxError => e
  end

  def unauthorized!
    headers['Content-Type'] = 'text/plain'
    headers['Content-Length'] = '0'
    headers['WWW-Authenticate'] = "Basic realm='Password protected'"
    halt 401
  end

  def dropbox_client
    @dropbox_client ||= DropboxClient.new(ENV["DROPBOX_TOKEN"])
  end
end
