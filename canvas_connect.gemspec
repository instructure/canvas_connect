# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'canvas_connect/version'

Gem::Specification.new do |gem|
  gem.name          = 'canvas_connect'
  gem.version       = CanvasConnect::VERSION
  gem.authors       = ['Zach Pendleton']
  gem.email         = ['zachp@instructure.com']
  gem.description   = %q{Canvas Connect is an Adobe Connect plugin for the Instructure Canvas LMS. It allows teachers and administrators to create and launch Connect conferences directly from their courses.}
  gem.summary       = %q{Adobe Connect integration for Instructure Canvas (http://instructure.com).}
  gem.homepage      = 'https://github.com/instructure/canvas_connect'
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = %w{app lib}

  gem.add_dependency 'rake', '>= 0.9.6'
  gem.add_dependency 'adobe_connect', '~> 1.0'
end

