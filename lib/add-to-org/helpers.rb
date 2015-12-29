module AddToOrg
  module Helpers

    # query api for the user's verified emails
    def verified_emails
      emails = client.emails :accept => 'application/vnd.github.v3'
      emails.select { |email| email.verified }
    end

    def valid?
      AddToOrg.validator.call(github_user, verified_emails, client)
    end

    private

    # user client
    def client
      @client ||= Octokit::Client.new :access_token => github_user.token
    end

    # org admin client
    def sudo_client
      @sudo_client ||= Octokit::Client.new :access_token => ENV['GITHUB_TOKEN']
    end

    # true if user is already a member of the org
    def member?
      client.organization_member? org_id, github_user.login
    end

    def team_id
      ENV['GITHUB_TEAM_ID']
    end

    def org_id
      ENV['GITHUB_ORG_ID']
    end

    # the main event...
    def add
      sudo_client.add_team_membership team_id, github_user.login
    end
  end
end
