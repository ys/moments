require 'json'
require 'yaml'

module MaRuKu
  module Helpers
    def md_im_image(children, url, title=nil, al=nil)
      if url.start_with?('/')
        url = "/t#{url}"
      end
      md_el(:im_image, children, { :url => url, :title => title }, al)
    end
  end
end

class Moments < Sinatra::Base

  configure :development do
    require 'pry'
  end

  configure :production do
    ENV['MEMCACHE_SERVERS']  = ENV['MEMCACHIER_SERVERS'] if ENV['MEMCACHIER_SERVERS']
    ENV['MEMCACHE_USERNAME'] = ENV['MEMCACHIER_USERNAME'] if ENV['MEMCACHIER_USERNAME']
    ENV['MEMCACHE_PASSWORD'] = ENV['MEMCACHIER_PASSWORD'] if ENV['MEMCACHIER_PASSWORD']

    set :cache, Dalli::Client.new

    use Rack::Cache,
      verbose:     true,
      metastore:   settings.cache,
      entitystore: settings.cache
  end

  get '/' do
    cache_control :public, max_age: 3600
    folder = folder("/")
    erb :index, locals: { moments: moments["moments"], text: text(folder) }
  end

  get '/custom.css' do
    cache_control :public, max_age: 3600
    content_type "text/css;charset=utf-8"
    dropbox_client.get_file('/custom.css')
  end

  get '/b' do
    cache_control :public, max_age: 3600
    folder = folder("/_posts")
    erb :posts, locals: { posts: posts }
  end

  get '/b/:path' do
    cache_control :public, max_age: 3600
    file = posts.detect{ |p| p['slug'] == params[:path] }["path"]
    text_content = dropbox_client.get_file(file)
    metadata = YAML.load(text_content)
    text = Maruku.new(text_content.sub(/^---\n(.*\n)*---\n/, '')).to_html
    erb :post, locals: { text: text, metadata: metadata }
  end

  get '/m/:path' do
    authorize!
    cache_control :public, max_age: 3600
    moment = moments["moments"].detect{|e| e["slug"] == params[:path] }
    folder = folder(moment["path"])
    pictures = folder['contents'].select { |e| is_a_picture?(e) }
    erb :moment, locals: { pictures: pictures, text: text(folder) }
  end

  get '/t/*' do
    cache_control :public, max_age: 3600

    t, metadata = dropbox_client.thumbnail_and_metadata("/#{params[:splat].first}", 'xl')
    content_type metadata['mime_type']
    t
  end

  get '/cache/flush' do
    flush_cache
  end

  post '/cache/flush' do
    flush_cache
  end

  def is_a_picture?(file)
    file['thumb_exists'] == true &&
      !file['path'].match(/_cover|password/) &&
      !file['path'].match(/index.md/)
  end

  def text(folder)
    text_file = folder['contents'].detect { |e| e['path'].match(/index.md/)}
    text = ''
    if text_file
      text_content = dropbox_client.get_file(text_file['path'])
      text = Maruku.new(text_content).to_html
    end
    text
  end

  def file(path)
    dropbox_client.get_file(path)
  end

  def moments
    content = dropbox_client.get_file('/index.yml')
    YAML.load(content)
  end

  def posts
    if settings.respond_to?(:cache)
      if @posts = settings.cache.get("_posts")
        @posts = YAML.load(@posts)
      else
        posts = get_posts
        settings.cache.set("_posts", YAML.dump(posts))
        @posts = posts
      end
    else
      get_posts
    end
  end

  def get_posts
    folder("_posts")["contents"].map do |f|
      content = file(f['path'])
      data = YAML.load(content)
      data['path'] = f['path']
      data
    end.sort_by{|p| - Date.parse(p["date"]).to_time.to_i }
  end

  def folder(path)
    dropbox_client.metadata("/#{path}", 25000, true, nil, nil, false, true)
  end

  def flush_cache
    halt 401 if ENV['FLUSH_TOKEN'] != params[:t]
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
    authorization.split(' ').last.unpack('m*').first
  end

  def authorization
    env['HTTP_AUTHORIZATION']
  end

  def password
    if settings.respond_to?('cache')
      settings.cache.get("#{params[:path]}/password")
    else
      fetch_and_cache_password
    end
  end

  def fetch_and_cache_password
    # puts env.inspect
    psw = dropbox_client.get_file("/#{params[:path]}/password.txt").strip

    if settings.respond_to?('cache')
      psw.tap { |p| settings.cache.set("#{params[:path]}/password", p) }
    end

    psw
  rescue DropboxError => e
    puts 'DropBox Password Error: ' + e.to_s
  end

  def unauthorized!
    headers['Content-Type'] = 'text/plain'
    headers['Content-Length'] = '0'
    headers['WWW-Authenticate'] = "Basic realm='Password protected'"
    halt 401
  end

  def dropbox_client
    @dropbox_client ||= DropboxClient.new(ENV['DROPBOX_TOKEN'])
  end
end
