require "spec_helper"

describe "logged out user" do

  include Rack::Test::Methods

  def app
    AddToOrg::App
  end

  it "asks you to log in" do
    get "/"
    expect(last_response.status).to eql(302)
    expect(last_response.headers['Location']).to match(%r{^https://github\.com/login/oauth/authorize})
  end
end

describe "logged in user" do

  include Rack::Test::Methods

  module AddToOrg
    class App < Sinatra::Base
      def valid?
        verified_emails.any? { |email| email[:email] =~ /@github\.com$/}
      end
    end
  end

  def app
    AddToOrg::App
  end

  before do
    @user = make_user('login' => 'benbaltertest')
    login_as @user
  end

  it "redirects if the user is a member" do
    with_env "GITHUB_ORG_ID", "some_org" do
      stub_request(:get, "https://api.github.com/orgs/some_org/members/benbaltertest").
      to_return(:status => 204)
      get "/"
      expect(last_response.status).to eql(302)
      expect(last_response.headers['Location']).to eql("https://github.com/")

      get "/foo"
      expect(last_response.status).to eql(302)
      expect(last_response.headers['Location']).to eql("https://github.com/foo")

      get "/foo/bar"
      expect(last_response.status).to eql(302)
      expect(last_response.headers['Location']).to eql("https://github.com/foo/bar")
    end
  end

  it "denies acccess to invalid users" do
    with_env "GITHUB_ORG_ID", "some_org" do
      stub_request(:get, "https://api.github.com/orgs/some_org/members/benbaltertest").
      to_return(:status => 404)

      stub_request(:get, "https://api.github.com/user/emails").
      to_return(:status => 200, :body => fixture("invalid_emails.json"), :headers => { 'Content-Type'=>'application/json' })

      get "/"
      expect(last_response.status).to eql(403)
      expect(last_response.body).to match(/We're unable to verify your eligibility at this time/)
    end
  end

  it "tries to add valid users" do
    with_env "GITHUB_ORG_ID", "some_org" do
      stub_request(:get, "https://api.github.com/orgs/some_org/members/benbaltertest").
      to_return(:status => 404)

      stub_request(:get, "https://api.github.com/user/emails").
      to_return(:status => 200, :body => fixture("emails.json"), :headers => { 'Content-Type'=>'application/json' })

      stub = stub_request(:put, "https://api.github.com/teams/memberships/benbaltertest").
      to_return(:status => 204)

      get "/foo"
      expect(stub).to have_been_requested
      expect(last_response.status).to eql(200)
      expect(last_response.body).to match(/confirm your invitation to join the organization/)
      expect(last_response.body).to match(/https:\/\/github.com\/orgs\/some_org\/invitation/)
      expect(last_response.body).to match(/\?return_to=https:\/\/github.com\/foo/)
    end
  end

  it "includes the requested URL" do
    with_env "GITHUB_ORG_ID", "some_org" do
      stub_request(:get, "https://api.github.com/orgs/some_org/members/benbaltertest").
      to_return(:status => 404)

      stub_request(:get, "https://api.github.com/user/emails").
      to_return(:status => 200, :body => fixture("emails.json"), :headers => { 'Content-Type'=>'application/json' })

      stub = stub_request(:put, "https://api.github.com/teams/memberships/benbaltertest").
      to_return(:status => 204)

      get "/foo/bar"
      expect(stub).to have_been_requested
      expect(last_response.status).to eql(200)
      expect(last_response.body).to match(Regexp.new('<a href="https://github.com/foo/bar">https://github.com/foo/bar</a>'))
    end
  end
end
