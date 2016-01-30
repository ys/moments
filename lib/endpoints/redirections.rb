module Endpoints
  class Redirections < Base
    subdomain false do
      get "/b/*" do
        redirect "#{protocol}://blog.#{ENV['DOMAIN']}/#{params["splat"][0]}"
      end

      get "/m/*" do
        redirect "#{protocol}://moments.#{ENV['DOMAIN']}/#{params["splat"][0]}"
      end

      def protocol
        if settings.production?
          "https"
        else
          "http"
        end
      end
    end
  end
end
