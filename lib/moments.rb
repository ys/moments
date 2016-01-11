class Moments < DropboxFolder
  include Enumerable

  def initialize
    super("/")
  end

  def find(path)
    detect { |e| e.slug == path }
  end

  def each
    _all.each do |moment|
      yield moment
    end
  end

  def _all
    @_all ||= @folder["contents"]
    .reject do |f|
      f["is_dir"] == false ||
      f["path"].start_with?("/_") ||
      f["path"] == "/assets"
    end.map do |f|
      m_alias = _aliases[f["path"][1..-1]] || {}
      Moment.new(
        title: m_alias["title"] || f["path"][1..-1],
        slug:  m_alias["slug"] || URI.escape(f["path"][1..-1].downcase.tr(" ", "_")),
        path:  f["path"]
      )
    end
  end

  def _aliases
    @aliases ||= DropboxFile.new("/moments.yml").to_yml
  rescue
    {}
  end
end
