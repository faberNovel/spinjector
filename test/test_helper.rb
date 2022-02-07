$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require "minitest/autorun"
require 'minitest/hooks/test'
require "minitest/reporters"

Minitest::Reporters.use! Minitest::Reporters::ProgressReporter.new

class TestCase < Minitest::Test
  include Minitest::Hooks
end
