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
