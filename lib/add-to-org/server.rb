module AddToOrg
  class App < Sinatra::Base

    use Rack::Session::Cookie, {
      :http_only => true,
      :secret => ENV['SESSION_SECRET'] || SecureRandom.hex
    }

    register Sinatra::Auth::Github

    set :views, File.expand_path("views", File.dirname(__FILE__))

    # require ssl
    configure :production do
      require 'rack-ssl-enforcer'
      use Rack::SslEnforcer
    end

    # dat auth
    before do
      session[:return_to] = request.url #store requested URL for post-auth redirect
      authenticate!
    end

    def success(locals={})
      erb :success, locals
    end

    def forbidden
      status 403
      erb :forbidden
    end

    def error
      status 500
      erb :error
    end

    # request a GitHub (authenticated) URL
    get "/*" do

      path = request.path || "/#{team_id}"
      halt redirect "https://github.com#{path}", 302 if member?
      forbidden unless valid?

      if add
        success({ :redirect => "https://github.com#{path}" })
      else
        error
      end
    end
  end
end
