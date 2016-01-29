module Endpoints
  class Root < Base

    get "/" do
      cache_control :public, max_age: 3600
      erb :index, locals: { text: Index.new.to_html, main_class: "home" }
    end

    get "/custom.css" do
      cache_control :public, max_age: 3600
      content_type "text/css;charset=utf-8"
      DropboxFile.new("/custom.css").content
    end

    get "/cache/flush" do
      flush_cache
    end

    post "/cache/flush" do
      flush_cache
    end
  end
end
