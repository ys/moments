module Endpoints
  class CatchAll < Base
    subdomain false do
      get "/:path" do
        cache_control :public, max_age: 3600
        path = params[:path].split(".")[0].split("/")[0]
        file = DropboxFile.new("/#{path}.md")
        erb :index, locals: { text: file.to_html, main_class: path }
      end
    end
  end
end
