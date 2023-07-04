# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puppet-commit/version'

Gem::Specification.new do |spec|
  spec.name          = 'puppet-commit'
  spec.version       = PuppetCommit::VERSION
  spec.authors       = ['Puppet, Inc.']
  spec.summary       = 'A Ruby gem for automating Puppet module commits.'
  spec.description   = <<-DESC
      puppet-commit is a Ruby gem that automates commits for Puppet modules.
      It streamlines the process of committing changes to version control systems using AI.
  DESC
  spec.homepage      = 'https://github.com/puppetlabs/puppet-commit'
  spec.license       = 'MIT'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  
  # Specify the main entry point file
  spec.files = Dir[
      'README.md',
      'LICENSE',
      'lib/**/*',
      'spec/**/*',
  ]
  spec.require_paths = ['lib']

  # Specify any executables
  spec.executables   = ['puppet-commit']

  # Specify the test files
  spec.test_files    = Dir['spec/**/*_spec.rb']
end
