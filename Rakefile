#!/usr/bin/env rake
begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

Bundler::GemHelper.install_tasks

# Extract tasks for interacting with the dummy application
require 'rails'

APP_RAKEFILE = if Rails::VERSION::MAJOR == 3
  File.expand_path("../spec/dummy32/Rakefile", __FILE__)
else
  File.expand_path("../spec/dummy/Rakefile", __FILE__)
end

load "rails/tasks/engine.rake"

require "rspec/core/rake_task"
RSpec::Core::RakeTask.new(:spec)
task default: :spec
