require 'test_helper'
require_relative '../lib/spinjector/runner'
require 'fileutils'

class YamlParserTest < TestCase

  def test_execution_order_is_correct
    copy_empty_project_to_tmp_folder do |project_path|
      runner = Runner.new(project_path, './test/fixtures/execution.yaml')
      runner.run

      assert_equal(
        runner.project.targets.first.build_phases.map(&:display_name),
        [
          "[Test] BeforeCompile",
          "[SPI] BeforeCompile",
          "Sources",
          "[SPI] AfterCompile",
          "[Test] AfterCompile",
          "Frameworks",
          "Resources",
          "[Test] AfterAll",
          "[SPI] BeforeHeaders",
          "[SPI] AfterHeaders",
        ]
      )
    end
  end

  def test_should_delete_old_phases
    copy_empty_project_to_tmp_folder do |project_path|
      inplace_replace_pbxproj(project_path) do |content|
        content.gsub('[Test]', '[SPI]')
      end

      runner = Runner.new(project_path, './test/fixtures/empty.yaml')
      runner.run

      assert_equal(
        runner.project.targets.first.build_phases.map(&:display_name),
        [
          "Sources",
          "Frameworks",
          "Resources",
        ]
      )
    end
  end

  # Private

  def copy_empty_project_to_tmp_folder
    Dir.mktmpdir("spinjector") do |dir|
      FileUtils.copy_entry './test/fixtures/EmptyProject', dir
      yield File.join(dir, 'EmptyProject.xcodeproj')
    end
  end

  def inplace_replace_pbxproj(project_path)
    pbxproj_path = File.join(project_path, 'project.pbxproj')
    pbxproj_content = File.read(pbxproj_path)
    new_content = yield pbxproj_content
    File.open(pbxproj_path, "w") { |f| f << new_content }
  end

end
