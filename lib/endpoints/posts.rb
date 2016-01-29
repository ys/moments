module Endpoints
  class Posts < Base
    get "/b" do
      cache_control :public, max_age: 3600
      erb :posts, locals: { posts: Post.all, main_class: "posts" }
    end

    get "/b/:path" do
      cache_control :public, max_age: 3600
      post = Post.all.detect { |p| p.slug == params[:path] }
      erb :post, locals: { post: post, main_class: "post" }
    end
  end
end
