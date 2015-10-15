require 'octokit'
require 'sinatra_auth_github'
require 'dotenv'
require_relative 'add-to-org/helpers'

Dotenv.load

module AddToOrg
  class App < Sinatra::Base

    include AddToOrg::Helpers

    set :github_options, {
      :scopes => "read:org,user:email"
    }

    use Rack::Session::Cookie, {
      :http_only => true,
      :secret => ENV['SESSION_SECRET'] || SecureRandom.hex
    }

    ENV['WARDEN_GITHUB_VERIFIER_SECRET'] ||= SecureRandom.hex
    register Sinatra::Auth::Github

    set :views, File.expand_path("add-to-org/views", File.dirname(__FILE__))

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
      halt erb :success, :locals => locals
    end

    def forbidden
      status 403
      halt erb :forbidden
    end

    def error
      status 500
      halt erb :error
    end

    # request a GitHub (authenticated) URL
    get "/*" do

      path = request.path || "/#{team_id}"
      halt redirect "https://github.com#{path}", 302 if member?
      forbidden unless valid?

      if add
        success({ :redirect => "https://github.com#{path}", :org_id => org_id })
      else
        error
      end
    end
  end
end
