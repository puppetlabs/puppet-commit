# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

group :development do
  gem 'json'

  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-stack_explorer'

  gem 'rake', '>= 12.3.3'
  gem 'rspec', '~> 3.1'
  gem 'rspec-collection_matchers', '~> 1.0'
  gem 'rspec-its', '~> 1.0'
  gem 'rspec-json_expectations', '~> 1.4'
end

group :release do
  gem 'faraday-retry', '~> 2.0.0', require: false
  gem 'github_changelog_generator', require: false
end

group :coverage, optional: ENV['COVERAGE'] != 'yes' do
  gem 'simplecov', require: false
  gem 'simplecov-console', require: false
end

group :rubocop do
  gem 'rubocop', '~> 1.48.1', require: false
  gem 'rubocop-performance', '~> 1.16', require: false
  gem 'rubocop-rspec', '~> 2.19', require: false
end
