# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "protoplasm/version"

Gem::Specification.new do |s|
  s.name        = "protoplasm-blocking-client"
  s.version     = Protoplasm::VERSION
  s.authors     = ["Josh Hull"]
  s.email       = ["joshbuddy@gmail.com"]
  s.homepage    = "https://github.com/bazaarlabs/protoplasm"
  s.summary     = %q{A blocking client for a Protoplasm server}
  s.description = %q{A blocking client for a Protoplasm server.}

  s.rubyforge_project = "protoplasm-blocking-client"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "beefcake", "~> 0.3.7"

  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest', "~> 2.6.1"
end
