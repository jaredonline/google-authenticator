#!/usr/bin/env rake
require "bundler/setup"
require "bundler/gem_tasks"
require "appraisal"

begin
  # RSpec 2
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new do |t|
    t.pattern     = "spec/**/*_spec.rb"
    t.rspec_opts  = "--color --format documentation --backtrace"
  end
rescue LoadError
  # RSpec 1
  require "spec/rake/spectask"

  Spec::Rake::SpecTask.new(:spec) do |t|
    t.pattern     = "spec/**/*_spec.rb"
    t.spec_opts   = ["--color", "--format nested", "--backtrace"]
  end
end

desc "Default: Test the gem under all supported Rails versions."
task :default => ["appraisal:install"] do
  exec("rake appraisal spec")
end

