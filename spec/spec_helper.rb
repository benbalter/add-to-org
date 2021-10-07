require 'bundler/setup'
require 'fileutils'
require 'securerandom'

ENV['RACK_ENV'] = 'test'
ENV['GITHUB_CLIENT_ID'] = 'CLIENT_ID'
ENV['GITHUB_CLIENT_SECRET'] = 'CLIENT_SECRET'
$:.push File.join(File.dirname(__FILE__), '..', 'lib')

require 'rack/test'
require 'sinatra/auth/github'
require 'sinatra/auth/github/test/test_helper'
require 'webmock/rspec'

require_relative '../lib/add-to-org'
WebMock.disable_net_connect!

RSpec.configure do |config|
  config.include(Sinatra::Auth::Github::Test::Helper)
end

def fixture_path(fixture)
  File.expand_path "./fixtures/#{fixture}", File.dirname(__FILE__)
end

def fixture(fixture)
  File.open(fixture_path(fixture)).read
end

def with_env(key, value)
  old_env = ENV[key]
  ENV[key] = value
  yield
  ENV[key] = old_env
end

class User < Warden::GitHub::User
  def self.make(attrs = {}, token = nil)
    default_attrs = {
      'login' => 'test_user',
      'name' => 'Test User',
      'email' => 'test@example.com',
      'company' => 'GitHub',
      'gravatar_id' => 'a' * 32,
      'avatar_url' => 'https://a249.e.akamai.net/assets.github.com/images/gravatars/gravatar-140.png?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-user-420.png'
    }
    default_attrs.merge! attrs
    User.new(default_attrs, token)
  end
end
