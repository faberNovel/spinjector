require 'test_helper'
require_relative '../lib/spinjector/yaml_parser'

class YamlParserTest < TestCase

  def test_should_parse_yaml
    parser = YAMLParser.new('./test/fixtures/parser.yaml')
    target = parser.configuration.targets.first

    refute_nil target
    assert_equal target.name, "Main"

    script = target.scripts.first
    refute_nil script
    assert_equal script.name, "Foo"
    assert_equal script.execution_position, :after_compile
  end
end
