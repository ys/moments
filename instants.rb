require "json"

class Instants < Sinatra::Base

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
    instants = dropbox_client.metadata("/")["contents"].sort_by {|e| e["client_mtime"] }
    puts instants
    erb :index, locals: { instants: instants }
  end

  get "/:path" do
    authorize(params[:path])
    cache_control :public, max_age: 3600
    folder = dropbox_client.metadata("/#{params[:path]}", 25000, true, nil, nil, false, true)
    pictures = folder["contents"].select { |e| e["thumb_exists"] == true && !e["path"].match(/_cover\./)}
    erb :instant, locals: { pictures: pictures }
  end

  get "/thumbs/*" do
    cache_control :public, max_age: 36000
    t, metadata = dropbox_client.thumbnail_and_metadata("/#{params[:splat].first}", "xl")
    content_type metadata["mime_type"]
    t
  end

  get "/cache/flush" do
    if ENV["FLUSH_TOKEN"] != params[:t]
      halt 401
    end
    settings.cache.flush
    params[:challenge]
  end

  post "/cache/flush" do
    if ENV["FLUSH_TOKEN"] != params[:t]
      halt 401
    end
    settings.cache.flush
    params[:challenge]
  end

  def authorize(path)
    return unless password(path)
    authorization = env["HTTP_AUTHORIZATION"]
    if authorization
      #WOW SUCH UGLY
      given_pwd = authorization.split(" ")
        .last.unpack("m*").first.split(/:/, 2)[1]
      if password(path) != given_pwd
        unauthorized!
      end
    else
      unauthorized!
    end
  end

  def password(path)
    @password ||= settings.cache.get(path) || fetch_and_cache_password(path)
  end

  def fetch_and_cache_password(path)
    dropbox_client.get_file("/#{path}/password.txt")
      .tap {|p| settings.cache.set(path, p) }
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
