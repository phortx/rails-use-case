# frozen_string_literal: true

# Extend loadpath for simpler require statements
$LOAD_PATH << "#{Dir.pwd}/lib/"

require 'rspec'
require 'rspec/mocks'
require 'simplecov'
require 'pp'
require 'fakefs/safe'

# Load all support files
Dir['spec/support/**/*.rb'].sort.each(&method(:require))

SimpleCov.formatters = [SimpleCov::Formatter::HTMLFormatter]

SimpleCov.start do
  add_filter 'spec'
  add_filter 'vendor'
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
end
