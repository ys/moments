module Endpoints
  class Posts < Base
    subdomain "blog" do
      get "/" do
        cache_control :public, max_age: 3600
        erb :posts, locals: { posts: Post.all, main_class: "posts" }
      end

      get "/custom.css" do
        cache_control :public, max_age: 3600
        content_type "text/css;charset=utf-8"
        DropboxFile.new("/custom.css").content
      end

      get "/:path" do
        cache_control :public, max_age: 3600
        post = Post.all.detect { |p| p.slug == params[:path] }
        erb :post, locals: { post: post, main_class: "post" }
      end
    end
  end
end
