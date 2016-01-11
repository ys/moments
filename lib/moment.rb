class Moment < DropboxFolder
  attr_accessor :title, :slug, :path

  def self.all
    Moments.new
  end

  def self.find(path)
    all.find(path)
  end

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
