# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'quiver/version'

Gem::Specification.new do |spec|
  spec.name          = "quiver"
  spec.version       = Quiver::VERSION
  spec.authors       = ["NCC Group Domain Services"]
  spec.email         = ["brady.love@nccgroup.trust", "emily.dobervich@nccgroup.trust"]
  spec.licenses      = ['MIT']

  spec.summary       = %q{Quiver is web API framework}
  spec.description   = %q{Quiver is a framework for writing web APIs}

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.executables << "quiver"
  spec.require_paths = ["lib"]

  spec.add_dependency "shotgun", "~> 0.9"
  spec.add_dependency "thor", "~> 0.19"
  spec.add_dependency "rack", "~> 1.5"
  spec.add_dependency "activesupport"
  spec.add_dependency "lotus-router", "0.3.0"
  spec.add_dependency "lotus-controller", "0.4.0"
  spec.add_dependency "pry"
  spec.add_dependency "extant", "~> 0.3"
  spec.add_dependency "rake", "~> 10.0"

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rack-test"
  spec.add_development_dependency "activerecord"
  spec.add_development_dependency "delayed_job_active_record"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "factory_girl"
  spec.add_development_dependency "ffaker"
  spec.add_development_dependency "database_cleaner"
  spec.add_development_dependency "timecop"
end
