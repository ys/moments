class MomentsApp < Sinatra::Base
  configure :development do
    require "pry"
  end

  configure :production do
    ENV["MEMCACHE_SERVERS"]  = ENV["MEMCACHIER_SERVERS"] if ENV["MEMCACHIER_SERVERS"]
    ENV["MEMCACHE_USERNAME"] = ENV["MEMCACHIER_USERNAME"] if ENV["MEMCACHIER_USERNAME"]
    ENV["MEMCACHE_PASSWORD"] = ENV["MEMCACHIER_PASSWORD"] if ENV["MEMCACHIER_PASSWORD"]

    set :cache, Dalli::Client.new

    use Rack::Cache,
        verbose:     true,
        metastore:   settings.cache,
        entitystore: settings.cache
  end

  get "/" do
    cache_control :public, max_age: 3600
    erb :index, locals: { text: Index.new.to_html, main_class: "home" }
  end

  get "/m" do
    cache_control :public, max_age: 3600
    moments = Moment.all
    etag moments.modified_at
    erb :moments, locals: { moments: moments, main_class: "moments" }
  end

  get "/m/:path" do
    authorize!
    cache_control :public, max_age: 3600
    moment = Moment.find(params[:path])
    erb :moment, locals: { moment: moment, main_class: "moment" }
  end

  get "/custom.css" do
    cache_control :public, max_age: 3600
    content_type "text/css;charset=utf-8"
    DropboxFile.new("/custom.css").content
  end

  get "/b" do
    cache_control :public, max_age: 3600
    erb :posts, locals: { posts: Post.all, main_class: "posts" }
  end

  get "/b/:path" do
    cache_control :public, max_age: 3600
    post = Post.all.detect { |p| p.slug == params[:path] }
    erb :post, locals: { post: post, main_class: "post" }
  end

  get "/t/*" do
    cache_control :public, max_age: 3600
    p = Picture.new("/#{params[:splat].first}")
    content_type p.mime_type
    p.content
  end

  get "/cache/flush" do
    flush_cache
  end

  post "/cache/flush" do
    flush_cache
  end

  get "/:path" do
    cache_control :public, max_age: 3600
    path = params[:path].split(".")[0].split("/")[0]
    file = DropboxFile.new("/#{path}.md")
    erb :index, locals: { text: file.to_html, main_class: path }
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
