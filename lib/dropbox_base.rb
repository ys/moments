class DropboxBase
  def file(path)
    client.get_file(path)
  rescue
    ""
  end

  def folder(path)
    client.metadata("/#{path}", 25_000, true, nil, nil, false, true)
  end

  def client
    self.class.client
  end

  def is_a_picture?(file)
    file["thumb_exists"] == true &&
      !file["path"].match(/_cover|password/) &&
      !file["path"].match(/index.md/)
  end

  def self.client
    @client ||= get_client
  end

  def self.get_client
    if ENV["OFFLINE"]
      OfflineDropboxClient.new
    else
      DropboxClient.new(ENV["DROPBOX_TOKEN"])
    end
  end
end
