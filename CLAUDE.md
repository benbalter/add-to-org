# CLAUDE.md

`add-to-org` is a Ruby gem containing a small Sinatra app: a user signs in with GitHub OAuth, a validator you define decides whether they qualify, and a bot token adds them to an org team before redirecting to the GitHub URL they asked for. It's published to RubyGems and mounted from someone else's `config.ru`; the [README](README.md) covers setup, environment variables, and the validator and view hooks.

## Commands

- `script/bootstrap` runs `bundle install`. `Gemfile.lock` is gitignored, as usual for a gem.
- `script/cibuild` is what CI runs ([ci.yml](.github/workflows/ci.yml), on Ruby 4.0): `bundle exec rake spec`, `bundle exec rubocop`, then `gem build`. The build leaves an `add-to-org-*.gem` in the repo root; it's gitignored, but delete it.
- `bundle exec rubocop -a` for autofixes. [`.rubocop_todo.yml`](.rubocop_todo.yml) holds the grandfathered offenses; shrink it rather than adding to it.
- `script/server` runs `rackup`, but there's no `config.ru` in this repo, so local runs need a host app like the [add-to-org demo](https://github.com/benbalter/add-to-org-demo).

## Architecture

- [`lib/add-to-org.rb`](lib/add-to-org.rb): the `AddToOrg` config module (`validator`, `views_dir`, `public_dir`) and `AddToOrg::App`, whose single `get '/*'` route does the redirect, validate, and add flow.
- [`lib/add-to-org/helpers.rb`](lib/add-to-org/helpers.rb): env-var accessors, the Octokit clients, membership checks, and the team add.
- [`lib/add-to-org/views/`](lib/add-to-org/views/): default `success`, `forbidden`, and `error` ERB templates, overridable by the host app.
- Specs in [`spec/`](spec/) use WebMock with net connections disabled and the `sinatra_auth_github` test helper to fake login, so they need no credentials.

## Releasing

[`script/release`](script/release) builds the gem, runs `gem push`, then tags `v<version>` and pushes `main` and the tag. Bump [`lib/add-to-org/version.rb`](lib/add-to-org/version.rb) first. Publishing is outward-facing and can't be undone: only run it with the owner's explicit go-ahead.

## Gotchas

- `SESSION_SECRET` and `WARDEN_GITHUB_VERIFIER_SECRET` aren't in the README's env var list, but without them each falls back to a random value per process, so sessions and OAuth state break across restarts or multiple instances.
- `Dotenv.load` runs at require time outside production, so a local `.env` (gitignored) supplies the env vars in development.
- `Rack::SslEnforcer` is only enabled when `RACK_ENV=production`.
- The gem depends on `ostruct` explicitly because Ruby 4.0 no longer ships it as a default gem.
