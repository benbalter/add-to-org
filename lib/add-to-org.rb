require 'octokit'
require 'sinatra_auth_github'
require 'dotenv'
require_relative 'add-to-org/server'

Dotenv.load

module AddToOrg
  class App < Sinatra::Base

    set :github_options, {
      :scopes    => "user,user:email",
      :secret    => ENV['GITHUB_CLIENT_SECRET'],
      :client_id => ENV['GITHUB_CLIENT_ID']
    }

    def user
      env['warden'].user
    end

   # user client
    def client
      @client ||= Octokit::Client.new :access_token => user.token
    end

     # new org admin client
    def sudo_client
      @sudo_client ||= Octokit::Client.new :access_token => ENV['GITHUB_TOKEN']
    end

    # query api for the user's verified emails
    def verified_emails
      emails = client.emails :accept => 'application/vnd.github.v3'
      emails.select { |email| email.verified }
    end

     # true if user is already a member of the org
    def member?
      client.organization_member? org_id, user.login
    end

    def valid?
      raise "You must define a custom valid? method to determine eligibility"
    end

    def team_id
      ENV['GITHUB_TEAM_ID']
    end

    def org_id
      ENV['GITHUB_ORG_ID']
    end

    # the main event...
    def add
      sudo_client.add_team_membership team_id, user.login
    end

  end
end
