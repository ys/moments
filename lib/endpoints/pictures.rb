module Endpoints
  class Pictures < Base
    subdomain :moments do
      get "/" do
        pictures_index
      end

      get "/:path" do
        pictures_page(params[:path])
      end
    end

    get "/m" do
      pictures_index
    end

    get "/m/:path" do
      pictures_page(params[:path])
    end

    get "/t/*" do
      cache_control :public, max_age: 3600
      p = Picture.new("/#{params[:splat].first}")
      content_type p.mime_type
      p.content
    end

    def pictures_page(path)
      authorize!
      cache_control :public, max_age: 3600
      moment = Moment.find(path)
      erb :moment, locals: { moment: moment, main_class: "moment" }
    end

    def pictures_index
      cache_control :public, max_age: 3600
      moments = Moment.all
      etag moments.modified_at
      erb :moments, locals: { moments: moments, main_class: "moments" }
    end
  end
end
