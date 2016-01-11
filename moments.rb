class DropboxBase
  def file(path)
    client.get_file(path)
  rescue
    ""
  end

  def folder(path)
    client.metadata("/#{path}", 25_000, true, nil, nil, false, true)
  end

  def client
    self.class.client
  end

  def is_a_picture?(file)
    file["thumb_exists"] == true &&
      !file["path"].match(/_cover|password/) &&
      !file["path"].match(/index.md/)
  end

  def self.client
    @client ||= DropboxClient.new(ENV["DROPBOX_TOKEN"])
  end
end

class DropboxFile < DropboxBase
  def initialize(path)
    @path = path
  end

  def content
    @content ||= full_content.sub(/^---\n(.*\n)*---\n/, "")
  end

  def metadata
    @metadata ||= YAML.load(full_content)
  end

  def to_html
    @html ||= Kramdown::Document.new(content).to_html
  end

  def to_yml
    @yml ||= YAML.load(content)
  end

  private

  def full_content
    @full_content ||= file(@path).force_encoding("UTF-8")
  end
end

class DropboxFolder < DropboxBase
  def initialize(path)
    @path = path
    @folder = folder(@path)
  end

  def modified_at
    @folder["modified_at"]
  end
end

class Index < DropboxFile
  def initialize
    @path = "/index.md"
  end
end

class Moments < DropboxFolder
  include Enumerable

  def initialize
    super("/")
  end

  def find(path)
    detect { |e| e.slug == path }
  end

  def each
    _all.each do |moment|
      yield moment
    end
  end

  def _all
    @_all ||= @folder["contents"]
    .reject do |f|
      f["is_dir"] == false ||
      f["path"].start_with?("/_") ||
      f["path"] == "/assets"
    end.map do |f|
      m_alias = _aliases[f["path"][1..-1]] || {}
      Moment.new(
        title: m_alias["title"] || f["path"][1..-1],
        slug:  m_alias["slug"] || URI.escape(f["path"][1..-1].downcase.tr(" ", "_")),
        path:  f["path"]
      )
    end
  end

  def _aliases
    @aliases ||= DropboxFile.new("/moments.yml").to_yml
  rescue
    {}
  end
end

class Moment < DropboxFolder
  attr_accessor :title, :slug, :path

  def initialize(opts = {})
    self.title = opts[:title]
    self.slug = opts[:slug]
    self.path = opts[:path]
    super(self.path)
  end

  def pictures
    @pictures ||= @folder["contents"]
      .select { |e| is_a_picture?(e) }
      .map { |p| Picture.new(p["path"]) }
  end

  def text
    text_file = @folder["contents"].detect { |e| e["path"].match(/index.md/) }
    text = ""
    if text_file
      text = DropboxFile.new(text_file["path"]).to_html
    end
    text
  end
end

class Picture < DropboxFile
  attr_reader :path

  def initialize(opts)
    super
    _load
  end

  def content
    @t
  end

  def mime_type
    @metadata["mime_type"]

  end

  def _load
    @t, @metadata = client.thumbnail_and_metadata(@path, "xl")
  end
end

class Posts < DropboxFolder
  include Enumerable

  def initialize
    super("/_posts")
  end

  def each
    _posts.each do |p|
      yield p
    end
  end

  def _posts
    get_posts
    # if settings.respond_to?(:cache)
    #   if @posts = settings.cache.get("_posts")
    #     @posts = YAML.load(@posts)
    #   else
    #     posts = get_posts
    #     settings.cache.set("_posts", YAML.dump(posts))
    #     @posts = posts
    #   end
    # else
    #   get_posts
    # end
  end

  def get_posts
    @_posts ||= @folder["contents"].map do |f|
      Post.new(f["path"])
    end.sort_by { |p| - p.created_at.to_time.to_i }
  end
end

class Post < DropboxFile
  def title
    metadata["title"]
  end

  def slug
    metadata["slug"]
  end

  def created_at
    Date.parse(metadata["date"])
  end
end

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
    moments = Moments.new
    etag moments.modified_at
    erb :moments, locals: { moments: moments, main_class: "moments" }
  end

  get "/m/:path" do
    authorize!
    cache_control :public, max_age: 3600
    moment = Moments.new.find(params[:path])
    erb :moment, locals: { moment: moment, main_class: "moment" }
  end

  get "/custom.css" do
    cache_control :public, max_age: 3600
    content_type "text/css;charset=utf-8"
    DropboxFile.new("/custom.css").content
  end

  get "/b" do
    cache_control :public, max_age: 3600
    erb :posts, locals: { posts: Posts.new, main_class: "posts" }
  end

  get "/b/:path" do
    cache_control :public, max_age: 3600
    post = Posts.new.detect { |p| p.slug == params[:path] }
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
