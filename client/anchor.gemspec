# -*- encoding: utf-8 -*-
require File.expand_path('../lib/anchor/version', __FILE__)

Gem::Specification.new do |s|
  s.name = 'anchor'
  s.version = Anchor::VERSION.dup
  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
  s.required_ruby_version = Gem::Requirement.new(">= 1.9.2")
  s.authors = ['Brian Moseley']
  s.description = 'Anchor listing service client library'
  s.email = ['bcm@copious.com']
  s.homepage = 'http://github.com/utahstreetlabs/anchor'
  s.rdoc_options = ['--charset=UTF-8']
  s.summary = "A client library for the Anchor listing service"
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.files = `git ls-files -- lib/*`.split("\n")
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")

  s.add_development_dependency('rake')
  s.add_development_dependency('mocha')
  s.add_development_dependency('rspec')
  s.add_development_dependency('gemfury')
  s.add_runtime_dependency('ladon', '>= 4.1.2')
end
