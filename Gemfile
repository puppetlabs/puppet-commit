# frozen_string_literal: true

source ENV['GEM_SOURCE'] || 'https://rubygems.org'

gemspec

group :required do
    gem 'ruby-openai', '~> 4.0', require: true
end

group :rubocop do
  gem 'rubocop', '~> 1.48.1', require: false
  gem 'rubocop-performance', '~> 1.16', require: false
  gem 'rubocop-rspec', '~> 2.19', require: false
end
