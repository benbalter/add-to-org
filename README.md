# Add to Org

*A simple Oauth App to automatically add users to an organization*

## Usage

Once set up, simply swap out your app's domain for any GitHub URL. E.g., `github.com/government/best-practices/issues/1` becomes `government-community.githubapp.com/government/best-practices/1`. The user will be authenticated, added to the organization, and redirected to the requested GitHub URL.

## Setup

1. Create [an oauth app](github.com/settings/applications/new)
2. Create a personal access token for a user with admin rights to the organization
3. Add `gem 'add-to-org' to your project's Gemfile
4. Add the following to a `config.ru` file:

```ruby
require 'add-to-org'
run AddToOrg::App
```

## Configuration

The following environmental values should be set:

* `GITHUB_ORG_ID` - The name of the org to add users to
* `GITHUB_TEAM_ID` - The ID of the team to add users to. Get this from the team page's URL
* `GITHUB_CLIENT_ID` - Your OAuth app's client ID
* `GITHUB_CLIENT_SECRET` - Your Oauth app's client secret
* `GITHUB_TOKEN` - A personal access token for a user with admin rights to the organization
* `CONTACT_EMAIL` - Point of contact to point users to if something goes wrong

You'll also need to monkey patch a validation method to determine if a user should be added, e.g.:

```ruby
require 'add-to-org'

module AddToOrg
  class App < Sinatra::Base
    def valid?
      verified_emails.any? { |email| email.match /\.foo\.gov$/}
    end
  end
end  
```

## Customizing Views

There are three views, `success`, `forbidden`, and `error`. They're pretty boring by default, so you may want to swap them out for something a bit my snazzy. There are two ways to do that:

```ruby
module AddToOrg
  class App < Sinatra::Base
    set :views, "path/to/your/views"
  end
end  
```

or by overwriting the `success`, `forbidden`, and `error` methods entirely:

```ruby
module AddToOrg
  class App < Sinatra::Base  
    def success(locals={})
      erb :some_template, locals
    end
  end
end
```
