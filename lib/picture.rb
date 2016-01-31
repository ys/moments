class Picture < DropboxFile
  attr_reader :path

  def initialize(opts)
    super
    _load
  end

  def content
    @t
  end

  def mime_type
    @metadata["mime_type"]
  end

  def _load
    @t, @metadata = client.thumbnail_and_metadata(@path, "xl")
  end
end
