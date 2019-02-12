source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.5.3'

gem 'rails', '~> 5.2.2'
gem 'pg', '>= 0.18', '< 2.0'
gem 'puma', '~> 3.11'
gem 'webpacker', '~> 3.5', '>= 3.5.5'
gem 'bootsnap', '>= 1.1.0', require: false
gem 'memoist', '~> 0.16.0'
gem 'sidekiq', '~> 5.2.5'

group :development, :test do
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'dotenv-rails', '~> 2.6'
  gem 'rspec-rails', '~> 3.8', '>= 3.8.2'
  gem 'factory_bot_rails', '~> 4.11', '>= 4.11.1'
  gem 'rails-controller-testing', '~> 1.0', '>= 1.0.4'
  gem 'pry-rails', '~> 0.3.9'
  gem 'pry-byebug', '~> 3.6'
end

group :development do
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'rubocop', '~> 0.63.1', require: false
  gem 'better_errors', '~> 2.5'
  gem 'binding_of_caller', '~> 0.8.0'
end

group :test do
  gem 'rspec_junit_formatter', '~> 0.4.1'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]
