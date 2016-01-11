class Post < DropboxFile

  def self.all
    Posts.new
  end

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

