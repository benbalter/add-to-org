require "spec_helper"

describe "config" do
  [:views_dir, :public_dir, :validator].each do |var|
    after do
      AddToOrg.send("#{var}=", nil)
    end

    it "accepts #{var}" do
      expected = SecureRandom.hex
      AddToOrg.send("#{var}=", expected)
      expect(AddToOrg.send(var)).to eql(expected)
    end
  end
end

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

  [:proc, :block, :lambda].each do |method|
    describe "with validator passed as a #{method}" do

      before(:each) do
        if method == :block
          AddToOrg.set_validator do |github_user, verified_emails, client|
            verified_emails.any? { |email| email[:email] =~ /@github\.com$/ }
          end
        elsif method == :proc
          AddToOrg.validator = proc { |github_user, verified_emails, client|
            verified_emails.any? { |email| email[:email] =~ /@github\.com$/ }
          }
        elsif method == :lambda
          AddToOrg.validator = lambda { |github_user, verified_emails, client|
            verified_emails.any? { |email| email[:email] =~ /@github\.com$/ }
          }
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

          stub = stub_request(:put, "https://api.github.com/teams//memberships/benbaltertest").
          with(
            body: "{}",
            headers: {
           'Accept'=>'application/vnd.github.v3+json',
           'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
           'Authorization'=>'token ghu_kgMurZBGt9Y75YNG2eYF4OWoZVUX0C2VQzsa',
           'Content-Type'=>'application/json',
           'User-Agent'=>'Octokit Ruby Gem 4.21.0'
            }).
          to_return(status: 200, body: "", headers: {})

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

          stub = stub_request(:put, "https://api.github.com/teams//memberships/benbaltertest").
          with(
            body: "{}",
            headers: {
           'Accept'=>'application/vnd.github.v3+json',
           'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
           'Authorization'=>'token ghu_kgMurZBGt9Y75YNG2eYF4OWoZVUX0C2VQzsa',
           'Content-Type'=>'application/json',
           'User-Agent'=>'Octokit Ruby Gem 4.21.0'
            }).
          to_return(status: 200, body: "", headers: {})

          get "/foo/bar"
          expect(stub).to have_been_requested
          expect(last_response.status).to eql(200)
          expect(last_response.body).to match(Regexp.new('<a href="https://github.com/foo/bar">https://github.com/foo/bar</a>'))
        end
      end
    end
  end
end
