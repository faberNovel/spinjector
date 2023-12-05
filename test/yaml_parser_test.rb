require 'test_helper'
require_relative '../lib/spinjector/yaml_parser'
require_relative '../lib/spinjector/logger'

class YamlParserTest < TestCase

  def test_should_parse_yaml
    parser = YAMLParser.new('./test/fixtures/parser.yaml', EmptyLogger.new)
    target = parser.configuration.targets.first

    refute_nil target
    assert_equal target.name, "Main"

    script = target.scripts.first
    refute_nil script
    assert_equal script.name, "Foo"
    assert_equal script.execution_position, :after_compile
    assert_equal script.show_env_vars_in_log, "0"

    default_values_script = target.scripts[1]
    refute_nil default_values_script
    assert_equal default_values_script.name, "Defaults"
    assert_equal default_values_script.input_paths, []
    assert_equal default_values_script.output_paths, []
    assert_equal default_values_script.input_file_list_paths, []
    assert_equal default_values_script.output_file_list_paths, []
    assert_nil default_values_script.dependency_file
    assert_equal default_values_script.execution_position, :before_compile
    assert_nil default_values_script.show_env_vars_in_log
  end
end
