# Add to Org

*A simple Oauth App to automatically add users to an organization*

[![Gem Version](https://badge.fury.io/rb/add-to-org.svg)](http://badge.fury.io/rb/add-to-org) [![Build Status](https://travis-ci.org/benbalter/add-to-org.svg)](https://travis-ci.org/benbalter/add-to-org)

## Usage

Once set up, simply swap out your app's domain for any GitHub URL. E.g., `github.com/government/best-practices/issues/1` becomes `government-community.githubapp.com/government/best-practices/1`. The user will be authenticated, added to the organization, and redirected to the requested GitHub URL.

## Setup

*Pro-tip: for a quickstart on how to set up the app, see the [add-to-org demo app](https://github.com/benbalter/add-to-org-demo).*

### Credentials

You'll need a few different credentials for things to work:

#### A bot account

You'll need a dedicated "bot" account to add users to the organization:

1. [Create a bot account](https://github.com/signup) (a standard GitHub account not used by a human) that has *admin* rights to your organization.
2. [Create a personal access token](https://github.com/settings/tokens/new) for that user, with `admin:org` scope.

#### An OAuth application

You'll also need to create an OAUth application to validate users:

1. Create an OAauth application *within your organization* via `https://github.com/organizations/[YOUR-ORGANIZATION-NAME]/settings/applications/new`
2. The homepage URL should be the URL to your production instance.
3. You can leave the callback URL blank. The default is fine.

## Developing locally and deploying

*Pro-tip: for a quickstart on how to set up the app, see the [add-to-org demo app](https://github.com/benbalter/add-to-org-demo)*

1. Create [an oauth app](github.com/settings/applications/new) (see above)
2. Create a personal access token for a user with admin rights to the organization (see above)
3. Add `gem 'add-to-org' to your project's Gemfile
4. Add the following to your project's `config.ru` file:

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

### Customizing the validator

For Add to Org to work, you'll also need to define a custom validator. You can do this in your `configu.ru`, or in a separate file included into `config.ru`. Here's an example of a validator that confirms the user has a verified `@github.com` email address:

```ruby
require 'add-to-org'

AddToOrg.set_validator do |github_user, verified_emails, client|
  verified_emails.any? { |email| email[:email] =~ /@github\.com\z/ }
end

run AddToOrg::App
```

If you prefer, you can also pass the validator as a proc (or lambda):

```ruby
AddToOrg.validator = proc { |github_user, verified_emails, client|
  verified_emails.any? { |email| email[:email] =~ /@github\.com\z/ }
}
```

The validator will receive three  arguments to help you validate the user meets your criteria:

* `github_user` - the Warden user, which will contain information like username, company, and human-readable name
* `verified_emails` - an array of the user's verified emails
* `client` - An [Octokit.rb](https://github.com/octokit/octokit.rb) client, preset with the user's OAuth token.

The validator should return `true` if you'd like the current user added to the organization, or `false` if you'd like the user's request to be denied.

### Customizing Views

There are three views, `success`, `forbidden`, and `error`. They're pretty boring by default, so you may want to swap them out for something a bit my snazzy. If you had a views directory along side your `config.ru`, you can do so like this in your `config.ru` file:

```ruby
require 'add-to-org'

AddToOrgs.views_dir = File.expand_path("./views", File.dirname(__FILE__))

run AddToOrg::App
```

These are just sinatra `.erb` views. Take a look at [the default views](https://github.com/benbalter/add-to-org/tree/master/lib/add-to-org/views) for an example.

### Customizing static assets

You can also do the same with `AddToOrg.public_dir` for serving static assets (AddToOrg comes bundled with Bootstrap by default).

```ruby
require 'add-to-org'

AddToOrgs.public_dir = File.expand_path("./public", File.dirname(__FILE__))

run AddToOrg::App
```
