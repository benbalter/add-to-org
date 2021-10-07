require 'spec_helper'

describe 'AddToOrgHelpers' do
  class TestHelper
    include AddToOrg::Helpers

    def github_user
      User.make({ 'login' => 'benbaltertest' }, 'asdf1234')
    end

    def initialize(path = nil)
      @path = path
    end

    def request
      Rack::Request.new('PATH_INFO' => @path)
    end
  end

  before do
    @helper = TestHelper.new
  end

  it 'initializes the client' do
    expect(@helper.send(:client).class).to eql(Octokit::Client)
    expect(@helper.send(:client).instance_variable_get('@access_token')).to eql('asdf1234')
  end

  it 'initializes the sudo client' do
    with_env 'GITHUB_TOKEN', 'SUDO_TOKEN' do
      expect(@helper.send(:sudo_client).class).to eql(Octokit::Client)
      expect(@helper.send(:sudo_client).instance_variable_get('@access_token')).to eql('SUDO_TOKEN')
    end
  end

  it 'retrieves a users verified emails' do
    stub_request(:get, 'https://api.github.com/user/emails')
      .to_return(status: 200, body: fixture('emails.json'), headers: { 'Content-Type' => 'application/json' })
    expect(@helper.verified_emails.count).to be(1)
    expect(@helper.verified_emails.first[:email]).to eql('octocat@github.com')
  end

  it 'retrieves the org id' do
    with_env 'GITHUB_ORG_ID', 'some_org' do
      expect(@helper.send(:org_id)).to eql('some_org')
    end
  end

  it 'retrieves the team id' do
    with_env 'GITHUB_TEAM_ID', '1234' do
      expect(@helper.send(:team_id)).to eql('1234')
    end
  end

  it 'knows if a user is an org member' do
    with_env 'GITHUB_ORG_ID', 'some_org' do
      stub_request(:get, 'https://api.github.com/orgs/some_org/members/benbaltertest')
        .to_return(status: 204)
      expect(@helper.send(:member?)).to be(true)

      stub_request(:get, 'https://api.github.com/orgs/some_org/members/benbaltertest')
        .to_return(status: 404)
      expect(@helper.send(:member?)).to be(false)
    end
  end

  it 'knows how to add a member to an org' do
    with_env 'GITHUB_ORG_ID', 'some_org' do
      with_env 'GITHUB_TEAM_ID', '1234' do
        stub = stub_request(:put, 'https://api.github.com/teams/1234/memberships/benbaltertest')
               .to_return(status: 204)
        @helper.send(:add)
        expect(stub).to have_been_requested
      end
    end
  end

  it 'throws an error if valid? is not defined' do
    stub_request(:get, 'https://api.github.com/user/emails')
      .to_return(status: 200, body: fixture('emails.json'), headers: { 'Content-Type' => 'application/json' })

    AddToOrg.validator = nil
    error = 'You must define a custom validator to determine eligibility'
    expect { @helper.valid? }.to raise_error(error)
  end
end
