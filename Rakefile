# frozen_string_literal: true

require 'rubygems/package_task'
require 'rubygems/specification'
require 'bundler'

task default: [:spec]

require 'rspec/core/rake_task'
desc 'Run specs'
RSpec::Core::RakeTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
  t.rspec_opts = ['--order', 'rand', '--color']
end
