source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.5'

gem 'rails', '~> 5.2.3'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 3.12.1'
gem 'webpacker', '~> 4.0', '>= 4.0.7'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'memoist', '~> 0.16.0'
gem 'sidekiq', '~> 5.2.5'
gem 'sidekiq-history', '~> 0.0.11'
gem 'friendly_id', '~> 5.2', '>= 5.2.5'
gem 'turbolinks', '~> 5.2'
gem 'bootstrap_form', '~> 4.2'
gem 'audited', '~> 4.8'
gem 'local_time', '~> 2.1'
gem 'json_schema', '~> 0.20.4'
gem 'crypt_keeper', '~> 2.0', '>= 2.0.1'
gem 'default_value_for', '~> 3.1'
gem 'attr_json', '~> 0.6.0'
gem 'jwt', '~> 2.1'
gem 'octokit', '~> 4.13'
gem 'faraday', '~> 0.15.4'
gem 'faraday_middleware', '~> 0.13.1'
gem 'typhoeus', '~> 1.3', '>= 1.3.1'
gem 'wait', '~> 0.5.3'
gem 'hub-clusters-creator', github: 'appvia/hub-clusters-creator', tag: 'v0.0.8'

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails', '~> 2.7.2'
  gem 'rspec-rails', '~> 3.8', '>= 3.8.2'
  gem 'factory_bot_rails', '~> 5.0.1'
  gem 'rails-controller-testing', '~> 1.0', '>= 1.0.4'
  gem 'pry-rails', '~> 0.3.9'
  gem 'pry-byebug', '~> 3.7'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'rubocop', '~> 0.73.0', require: false
  gem 'rubocop-performance', '~> 1.4.0', require: false
  gem 'rubocop-rails', '~> 2.2', '>= 2.2.1', require: false
  gem 'better_errors', '~> 2.5.1'
  gem 'binding_of_caller', '~> 0.8.0'
end

group :test do
  gem 'rspec_junit_formatter', '~> 0.4.1'
  gem 'timecop', '~> 0.9.1'
  gem 'shoulda-matchers', '~> 4.1', '>= 4.1.2'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
