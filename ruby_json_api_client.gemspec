# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby_json_api_client/version'

Gem::Specification.new do |spec|
  spec.name          = "ruby_json_api_client"
  spec.version       = RubyJsonApiClient::VERSION
  spec.authors       = ["Ryan Toronto"]
  spec.email         = ["ryanto@gmail.com"]
  spec.summary       = %q{API client for activemodel instances}
  spec.description   = %q{API client for activemodel instances}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency 'json', '>= 1.8.1'
  spec.add_dependency 'faraday', '>= 0.9.0'
  spec.add_dependency 'addressable', '>= 2.3.6'
  spec.add_dependency 'activemodel', '>= 4.0'
  spec.add_dependency 'activesupport', '>= 4.0'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "pry"

  # testing
  spec.add_development_dependency "rspec", "~> 3.0.0"
  spec.add_development_dependency 'rspec-collection_matchers', '~> 1.0.0'
  spec.add_development_dependency 'rspec-its', '~> 1.0.1'
  spec.add_development_dependency 'webmock', '~> 1.18.0'

  # perf
  spec.add_development_dependency 'benchmark-ips', '~> 2.0.0'

  # http adapters (for perf testing)
  spec.add_development_dependency 'typhoeus', '~> 0.6.9'

  # json parsers (for perf testing)
  spec.add_development_dependency 'oj', '~> 2.10.0'
  spec.add_development_dependency 'yajl-ruby', '~> 1.2.1'
end
