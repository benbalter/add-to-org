require "spec_helper"

describe "AddToOrgHelpers" do

  class TestHelper
    include AddToOrg::Helpers

    def github_user
      User.make({"login" => "benbaltertest"}, "asdf1234")
    end

    def initialize(path=nil)
      @path = path
    end

    def request
      Rack::Request.new("PATH_INFO" => @path)
    end
  end

  before(:each) do
    @helper = TestHelper.new
  end

  it "initializes the client" do
    expect(@helper.send(:client).class).to eql(Octokit::Client)
    expect(@helper.send(:client).instance_variable_get("@access_token")).to eql("asdf1234")
  end

  it "initializes the sudo client" do
    with_env "GITHUB_TOKEN", "SUDO_TOKEN" do
      expect(@helper.send(:sudo_client).class).to eql(Octokit::Client)
      expect(@helper.send(:sudo_client).instance_variable_get("@access_token")).to eql("SUDO_TOKEN")
    end
  end

  it "retrieves a users verified emails" do
    stub_request(:get, "https://api.github.com/user/emails").
    to_return(:status => 200, :body => fixture("emails.json"), :headers => { 'Content-Type'=>'application/json' })
    expect(@helper.verified_emails.count).to eql(1)
    expect(@helper.verified_emails.first[:email]).to eql("octocat@github.com")
  end

  it "retrieves the org id" do
    with_env "GITHUB_ORG_ID", "some_org" do
      expect(@helper.send(:org_id)).to eql("some_org")
    end
  end

  it "retrieves the team id" do
    with_env "GITHUB_TEAM_ID", "1234" do
      expect(@helper.send(:team_id)).to eql("1234")
    end
  end

  it "knows if a user is an org member" do
    with_env "GITHUB_ORG_ID", "some_org" do
      stub_request(:get, "https://api.github.com/orgs/some_org/members/benbaltertest").
      to_return(:status => 204)
      expect(@helper.send(:member?)).to eql(true)

      stub_request(:get, "https://api.github.com/orgs/some_org/members/benbaltertest").
      to_return(:status => 404)
      expect(@helper.send(:member?)).to eql(false)
    end
  end

  it "knows how to add a mebmer to an org" do
    with_env "GITHUB_ORG_ID", "some_org" do
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
      @helper.send(:add)
      expect(stub).to have_been_requested
    end
  end

  it "throws an error if valid? is not defined" do
    stub_request(:get, "https://api.github.com/user/emails").
      to_return(:status => 200, :body => fixture("emails.json"), :headers => { 'Content-Type'=>'application/json' })

    AddToOrg.validator = nil
    error = "You must define a custom validator to determine eligibility"
    expect { @helper.valid? }.to raise_error(error)
  end
end
