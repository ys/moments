module MaRuKu
  module Helpers
    def md_im_image(children, url, title = nil, al = nil)
      url = "/t#{url}" if url.start_with?('/')
      md_el(:im_image, children, { url: url, title: title }, al)
    end
  end
end
