# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'bundler', '~> 1.16'
gem 'haml'

group :development, :test do
  gem 'rake', '~> 12.3'
  gem 'rspec', '~> 3.0'
  gem 'rspec_junit_formatter'
  gem 'rubocop'
end

group :development do
  gem 'commonmarker'
end

group :test do
  gem 'simplecov', require: false
end
