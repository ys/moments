require "json"

class Instants < Sinatra::Base

  cache = Dalli::Client.new

  use Rack::Cache,
    verbose:     true,
    metastore:   cache,
    entitystore: cache

  get '/' do
    cache_control :public, max_age: 3600
    erb :index, locals: { instants: dropbox_client.metadata("/")["contents"] }
  end

  get "/:path" do
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

  def dropbox_client
    @dropbox_client ||= DropboxClient.new(ENV["DROPBOX_TOKEN"])
  end
end
