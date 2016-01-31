class OfflineDropboxClient
  BASE_PATH = File.join(Dir.home, "Dropbox/Apps/your-moments")

  def get_file(path)
    path = path.gsub(BASE_PATH, "")
    File.read(File.join(BASE_PATH, path))

  end

  def metadata(path, *options)
    {
      "contents" => content_as_json(path)
    }
  end

  def content_as_json(dir_path)
    files_in_dir(dir_path).map do |path|
      json = {
        "path" => path.gsub(BASE_PATH, ""),
        "is_dir" => Dir.exist?(path)
      }
      if path =~ /\.(jpg|png)$/
        json["thumb_exists"] = true
      end
      json
    end
  end

  def thumbnail_and_metadata(path, size)
    [get_file(path), { "mime_type" => "image/png" }]
  end

  def files_in_dir(path)
    path = path.sub /^\//, ""
    Dir[File.join(BASE_PATH, path, "*")]
  end
end
