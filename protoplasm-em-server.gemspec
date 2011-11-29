# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "protoplasm/version"

Gem::Specification.new do |s|
  s.name        = "protoplasm-em-server"
  s.version     = Protoplasm::VERSION
  s.authors     = ["Josh Hull"]
  s.email       = ["joshbuddy@gmail.com"]
  s.homepage    = "https://github.com/bazaarlabs/protoplasm"
  s.summary     = %q{A protoplasm server backed by EventMachine}
  s.description = %q{A protoplasm server backed by EventMachine.}

  s.rubyforge_project = "protoplasm-em-server"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "eventmachine"
  s.add_dependency "beefcake", "~> 0.3.7"

  s.add_development_dependency 'rake'
  s.add_development_dependency 'minitest', "~> 2.6.1"
end
