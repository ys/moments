class DropboxFolder < DropboxBase
  def initialize(path)
    @path = path
    @folder = folder(@path)
  end

  def modified_at
    @folder["modified_at"]
  end
end
