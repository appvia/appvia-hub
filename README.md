# Appvia Hub

[![Build_Status](https://circleci.com/gh/appvia/appvia-hub.svg?style=svg&circle-token=ea303efa15990d76dc61bbbed4e4b634b578299f)](https://circleci.com/gh/appvia/appvia-hub)

## Dev

### Prerequisites

- Ruby 2.5.3
  - with Bundler v1.17+
- NodeJS 10+
  - with Yarn 1.10+
- Docker Compose v1.23+

### Dependent Services

A database, mock user service and auth proxy can all be run locally using Docker Compose, using the provided `docker-compose.yml`.

To start them all up (running in the background):

```shell
docker-compose up -d
```

To shut them all down:

```shell
docker-compose down
```

### Initial Setup

Once you have the prerequisites above, the codebase cloned and the dependent services running locally, run the following to set everything up:

```bash
bin/setup
```

Then you're ready to use the usual `rails` commands (like `bin/rails serve`) to run / work with the app. See the [Rails CLI guide](http://guides.rubyonrails.org/command_line.html) for details.

### Running the App

Start up the Rails server with:

```shell
bin/rails server
```

This serves the entire app, including all frontend assets (bundled using [Webpack](https://webpack.js.org/)).

You can **also** run `bin/webpack-dev-server` in a separate terminal shell if you want live reloading (in your browser) of CSS and JavaScript changes (note: only changes made within the `app/webpack` folder will cause live reloads).


### Dev Tips

To get Rubocop to fix detected issues automatically (where it can):

```shell
bundle exec rubocop -a
```
