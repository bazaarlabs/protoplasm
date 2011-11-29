require 'bundler/gem_tasks'
require 'rake/testtask'
require './lib/protoplasm/version'

task :test do
  Rake::TestTask.new do |t|
    Dir['test/*_test.rb'].each{|f| require File.expand_path(f)}
  end
end

def version
  Protoplasm::VERSION
end

def version_tag
  "v#{version}"
end

def tag_version
  system("git tag -a -m \"Version #{version}\" #{version_tag}") or raise("Cannot tag version")
  Bundler.ui.confirm "Tagged #{version_tag}"
  yield
rescue
  Bundler.ui.error "Untagged #{version_tag} due to error"
  system("git tag -d #{version_tag}") or raise("Cannot untag version")
  raise
end

desc "Release client & server (#{version})"
task :release do
  tag_version do
    Rake::Task["em_server:release_without_tagging"].invoke
    Rake::Task["blocking_client:release_without_tagging"].invoke
  end
end

desc "Install client & server (#{version})"
task :install do
  Rake::Task["em_server:install"].invoke
  Rake::Task["blocking_client:install"].invoke
end

desc "Build client & server (#{version})"
task :build do
  Rake::Task["em_server:build"].invoke
  Rake::Task["blocking_client:build"].invoke
end

namespace :em_server do
  helper = Bundler::GemHelper.new(File.dirname(__FILE__), "protoplasm-em-server")
  helper.install
  helper.instance_eval do
    task :release_without_tagging do
      guard_clean
      built_gem_path = build_gem
      git_push
      rubygem_push(built_gem_path)
    end
  end
end

namespace :blocking_client do
  helper = Bundler::GemHelper.new(File.dirname(__FILE__), "protoplasm-blocking-client")
  helper.install
  helper.instance_eval do
    task :release_without_tagging do
      guard_clean
      built_gem_path = build_gem
      git_push
      rubygem_push(built_gem_path)
    end
  end
end
