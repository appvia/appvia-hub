# Appvia Hub

[![Build_Status](https://circleci.com/gh/appvia/appvia-hub.svg?style=svg&circle-token=ea303efa15990d76dc61bbbed4e4b634b578299f)](https://circleci.com/gh/appvia/appvia-hub)

## Docs

Please refer to https://appvia.github.io/appvia-hub/ for the documentation.

## Preview / QA

These instructions allow you to quickly run the Hub in docker.

**Note** the container is built locally and the hub is run with the production rails environment so this isn't suitable for development.

**Note** for development, you will need to run the steps for [Dev](#dev) below.

Run the command:
```shell
docker-compose -f docker-compose.yml -f docker-compose-app-preview.yml up
```

The hub should then be available at http://localhost:3000

## Dev

### Prerequisites

- Ruby 2.5.5
  - with Bundler v1.17+
  - Postgres client ([platform lib required](https://stackoverflow.com/questions/6040583/cant-find-the-libpq-fe-h-header-when-trying-to-install-pg-gem?answertab=votes#tab-top))
- NodeJS 10+
  - with Yarn 1.10+
- Docker Compose v1.23+

### Dependent services

A database, mock user service and auth proxy can all be run locally using Docker Compose, using the provided `docker-compose.yml`.
Note for linux users you can use `docker-compose-linux.yml` and simply add the `docker-compose -f docker-compose.yml -f docker-compose-linux.yml <commands>`. This is required due to the current lack of support for `host.docker.internal` in [Docker for Linux](https://github.com/docker/for-linux/issues/264).

To start them all up (running in the background):

```shell
docker-compose up -d
```

To shut them all down:

```shell
docker-compose down
```

### Initial setup

Once you have the prerequisites above, the codebase cloned and the dependent services running locally…

Set up the following environment variables in `.env.local` (you'll need to create this file initially):
- `SECRET_KEY_BASE` – used for encryption. Usually 128 bytes. You can run `bin/rails secret` locally to generate a string for this.
- `SECRET_SALT` – a separate [salt](https://en.wikipedia.org/wiki/Salt_(cryptography)) value used for things like model attribute encryption.

Then run the following to set everything up:

```bash
bin/setup
```

Then you're ready to use the usual `rails` commands (like `bin/rails serve`) to run / work with the app. See the [Rails CLI guide](http://guides.rubyonrails.org/command_line.html) for details.

### Running the app locally

#### Web app server

Start up the Rails server with:

```shell
bin/rails server
```

This serves the entire app, including all frontend assets (bundled using [Webpack](https://webpack.js.org/)).

You can **also** run `bin/webpack-dev-server` in a separate terminal shell if you want live reloading (in your browser) of CSS and JavaScript changes (note: only changes made within the `app/webpack` folder will cause live reloads).

#### Tests

To run the test suite:

```shell
bundle exec rspec
```

#### Background workers

Certain tasks – such as resource provisioning – are carried out in background jobs using [Sidekiq](https://github.com/mperham/sidekiq).

There are different background workers for different types of jobs:

- One for **resource provisioning** specifically:
  - **IMPORTANT:** MUST run with a concurrency of 1 (`-c 1`) to ensure proper FIFO processing.
  - `bundle exec sidekiq -q resources -c 1`
- One for **admin tasks** specifically:
  - `bundle exec sidekiq -q admin_tasks -c 2`
- And one for everything else:
  - `bundle exec sidekiq -q default -c 5`

### Dev tips

To get Rubocop to fix detected issues automatically (where it can):

```shell
bundle exec rubocop -a
```

If you get the error `Invalid single-table inheritance type: […]` just restart your local server. This is due to single-table inheritance and lazy loading of files during development.
