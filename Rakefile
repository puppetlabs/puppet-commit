# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'bundler/gem_tasks'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = 'spec/acceptance/**/*.rb'
end

task default: :spec

begin
  require 'github_changelog_generator/task'

  GitHubChangelogGenerator::RakeTask.new :changelog do |config|
    config.header = "# Changelog\n\nAll notable changes to this project will be documented in this file."
    config.exclude_labels = %w[duplicate question invalid wontfix wont-fix skip-changelog modulesync]
    config.user = 'puppetlabs'
    config.project = 'puppet-lint-check_unsafe_interpolations'
    config.future_release = Gem::Specification.load("#{config.project}.gemspec").version
  end
rescue LoadError
end
