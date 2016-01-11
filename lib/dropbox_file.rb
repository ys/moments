class DropboxFile < DropboxBase
  def initialize(path)
    @path = path
  end

  def content
    @content ||= full_content.sub(/^---\n(.*\n)*---\n/, "")
  end

  def metadata
    @metadata ||= YAML.load(full_content)
  end

  def to_html
    @html ||= Kramdown::Document.new(content).to_html
  end

  def to_yml
    @yml ||= YAML.load(content)
  end

  private

  def full_content
    @full_content ||= file(@path).force_encoding("UTF-8")
  end
end

