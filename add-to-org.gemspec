require File.expand_path('../lib/add-to-org/version', __FILE__)

Gem::Specification.new do |s|
  s.name = "add-to-org"
  s.summary = "A simple Oauth App to automatically add users to an organization"
  s.description = "A simple Oauth App to automatically add users to an organization."
  s.version = AddToOrg::VERSION
  s.authors = ["Ben Balter"]
  s.email = "ben.balter@github.com"
  s.homepage = "https://github.com/benbalter/add-to-org"
  s.licenses = ["MIT"]

  s.files                 = `git ls-files`.split("\n")
  s.test_files            = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables           = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths         = ["lib"]

  s.require_paths = ["lib"]
  s.add_dependency "warden-github", "~> 1.1"
  s.add_dependency "sinatra_auth_github", "~> 1.1"
  s.add_dependency "octokit", "~> 4.0"
  s.add_dependency "rack-ssl-enforcer", "~> 0.2"
  s.add_dependency "dotenv", "~> 2.0"
  s.add_dependency "rake", "~> 10.3"
  s.add_development_dependency "rspec", "~> 3.1"
  s.add_development_dependency "rack-test", "~> 0.6"
  s.add_development_dependency "webmock", "~> 1.2 "
  s.add_development_dependency "pry", "~> 0.10"
end
