#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

# Extract tasks for interacting with the dummy application
APP_RAKEFILE = File.expand_path("../spec/dummy/Rakefile", __FILE__)
load "rails/tasks/engine.rake"

task default: :spec

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec) do |t|
  puts "\n==> Testing with Rails #{Rails::VERSION::STRING} and Ruby #{RUBY_VERSION} <==\n"
end
