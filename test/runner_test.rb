require 'test_helper'
require_relative '../lib/spinjector/runner'
require_relative '../lib/spinjector/logger'
require 'fileutils'
require 'xcodeproj'

LOGGER = EmptyLogger.new

class Xcodeproj::Project

  def ft_main_target
    targets.find { |t| t.name === "EmptyProject" }
  end

  def ft_framework_target
    targets.find { |t| t.name === "Framework" }
  end
end

class Xcodeproj::Project::Object::PBXNativeTarget

  def ft_build_phases_names
    build_phases.map(&:display_name)
  end
end

class RunnerParserTest < TestCase

  def test_execution_order_is_correct
    copy_empty_project_to_tmp_folder do |project_path|
      runner = Runner.new(project_path, './test/fixtures/execution.yaml', LOGGER)
      runner.run

      assert_equal(
        runner.project.ft_main_target.ft_build_phases_names,
        [
          "[Test] BeforeCompile",
          "[SPI] BeforeCompile",
          "Sources",
          "[SPI] AfterCompile",
          "[Test] AfterCompile",
          "Frameworks",
          "Resources",
          "Embed Frameworks",
          "[Test] AfterAll",
        ]
      )
      assert_equal(
        runner.project.ft_framework_target.ft_build_phases_names,
        [
          "[Test] BeforeHeaders",
          "[SPI] BeforeHeaders",
          "Headers",
          "[SPI] AfterHeaders",
          "[Test] AfterHeaders",
          "[Test] BeforeCompile",
          "[SPI] BeforeCompile",
          "Sources",
          "[SPI] AfterCompile",
          "[Test] AfterCompile",
          "Frameworks",
          "Resources",
          "[Test] AfterAll",
        ]
      )
    end
  end

  def test_should_delete_old_phases
    copy_empty_project_to_tmp_folder do |project_path|
      inplace_replace_pbxproj(project_path) do |content|
        content.gsub('[Test]', '[SPI]')
      end

      runner = Runner.new(project_path, './test/fixtures/empty.yaml', LOGGER)
      runner.run

      assert_equal(
        runner.project.ft_main_target.ft_build_phases_names,
        [
          "Sources",
          "Frameworks",
          "Resources",
          "Embed Frameworks",
        ]
      )
      assert_equal(
        runner.project.ft_framework_target.ft_build_phases_names,
        [
          "Headers",
          "Sources",
          "Frameworks",
          "Resources",
        ]
      )
    end
  end

  def test_reorder_inner_position
    copy_empty_project_to_tmp_folder do |project_path|
      runner = Runner.new(project_path, './test/fixtures/change_inner_position_before.yaml', LOGGER)
      runner.run

      assert_equal(
        runner.project.ft_main_target.ft_build_phases_names,
        [
          "[Test] BeforeCompile",
          "Sources",
          "[SPI] AfterCompile1",
          "[SPI] AfterCompile2",
          "[SPI] AfterCompile3",
          "[Test] AfterCompile",
          "Frameworks",
          "Resources",
          "Embed Frameworks",
          "[Test] AfterAll",
        ]
      )
      assert_equal(
        runner.project.ft_framework_target.ft_build_phases_names,
        [
          "[Test] BeforeHeaders",
          "Headers",
          "[SPI] AfterHeaders1",
          "[SPI] AfterHeaders2",
          "[Test] AfterHeaders",
          "[Test] BeforeCompile",
          "Sources",
          "[SPI] AfterCompile1",
          "[SPI] AfterCompile2",
          "[SPI] AfterCompile3",
          "[Test] AfterCompile",
          "Frameworks",
          "Resources",
          "[Test] AfterAll"
        ]
      )

      copy_empty_project_to_tmp_folder(File.dirname(project_path)) do |reorder_project_path|
        runner = Runner.new(reorder_project_path, './test/fixtures/change_inner_position_after.yaml', LOGGER)
        runner.run

        assert_equal(
          runner.project.ft_main_target.ft_build_phases_names,
          [
            "[Test] BeforeCompile",
            "Sources",
            "[SPI] AfterCompile3",
            "[SPI] AfterCompile1",
            "[SPI] AfterCompile2",
            "[Test] AfterCompile",
            "Frameworks",
            "Resources",
            "Embed Frameworks",
            "[Test] AfterAll",
          ]
        )
        assert_equal(
          runner.project.ft_framework_target.ft_build_phases_names,
          [
            "[Test] BeforeHeaders",
            "Headers",
            "[SPI] AfterHeaders2",
            "[SPI] AfterHeaders1",
            "[Test] AfterHeaders",
            "[Test] BeforeCompile",
            "Sources",
            "[SPI] AfterCompile3",
            "[SPI] AfterCompile1",
            "[SPI] AfterCompile2",
            "[Test] AfterCompile",
            "Frameworks",
            "Resources",
            "[Test] AfterAll"
          ]
        )
      end
    end
  end

  def test_reorder_outer_position
    copy_empty_project_to_tmp_folder do |project_path|
      runner = Runner.new(project_path, './test/fixtures/change_outer_position_before.yaml', LOGGER)
      runner.run

      assert_equal(
        runner.project.ft_main_target.ft_build_phases_names,
        [
          "[Test] BeforeCompile",
          "[SPI] BeforeCompileToBeforeCompile",
          "[SPI] BeforeCompileToAfterCompile",
          "Sources",
          "[SPI] AfterCompileToBeforeCompile",
          "[SPI] AfterCompileToAfterCompile",
          "[Test] AfterCompile",
          "Frameworks",
          "Resources",
          "Embed Frameworks",
          "[Test] AfterAll",
        ]
      )
      assert_equal(
        runner.project.ft_framework_target.ft_build_phases_names,
        [
          "[Test] BeforeHeaders",
          "[SPI] BeforeHeadersToBeforeHeaders",
          "[SPI] BeforeHeadersToAfterHeaders",
          "Headers",
          "[SPI] AfterHeadersToBeforeHeaders",
          "[SPI] AfterHeadersToAfterHeaders",
          "[Test] AfterHeaders",
          "[Test] BeforeCompile",
          "[SPI] BeforeCompileToBeforeCompile",
          "[SPI] BeforeCompileToAfterCompile",
          "Sources",
          "[SPI] AfterCompileToBeforeCompile",
          "[SPI] AfterCompileToAfterCompile",
          "[Test] AfterCompile",
          "Frameworks",
          "Resources",
          "[Test] AfterAll",
        ]
      )

      copy_empty_project_to_tmp_folder(File.dirname(project_path)) do |reorder_project_path|
        runner = Runner.new(reorder_project_path, './test/fixtures/change_outer_position_after.yaml', LOGGER)
        runner.run

        assert_equal(
          runner.project.ft_main_target.ft_build_phases_names,
          [
            "[Test] BeforeCompile",
            "[SPI] BeforeCompileToBeforeCompile",
            "[SPI] AfterCompileToBeforeCompile",
            "Sources",
            "[SPI] BeforeCompileToAfterCompile",
            "[SPI] AfterCompileToAfterCompile",
            "[Test] AfterCompile",
            "Frameworks",
            "Resources",
            "Embed Frameworks",
            "[Test] AfterAll",
          ]
        )
        assert_equal(
          runner.project.ft_framework_target.ft_build_phases_names,
          [
            "[Test] BeforeHeaders",
            "[SPI] BeforeHeadersToBeforeHeaders",
            "[SPI] AfterHeadersToBeforeHeaders",
            "Headers",
            "[SPI] BeforeHeadersToAfterHeaders",
            "[SPI] AfterHeadersToAfterHeaders",
            "[Test] AfterHeaders",
            "[Test] BeforeCompile",
            "[SPI] BeforeCompileToBeforeCompile",
            "[SPI] AfterCompileToBeforeCompile",
            "Sources",
            "[SPI] BeforeCompileToAfterCompile",
            "[SPI] AfterCompileToAfterCompile",
            "[Test] AfterCompile",
            "Frameworks",
            "Resources",
            "[Test] AfterAll",
          ]
        )
      end
    end
  end

  def test_runner_indempotent
    copy_empty_project_to_tmp_folder do |project_path|
      runner = Runner.new(project_path, './test/fixtures/execution.yaml', LOGGER)
      runner.run

      pbxproj_path = File.join(project_path, 'project.pbxproj')
      after_first_run_content = File.read(pbxproj_path)

      copy_empty_project_to_tmp_folder(File.dirname(project_path)) do |new_project_path|
        runner = Runner.new(new_project_path, './test/fixtures/execution.yaml', LOGGER)
        runner.run

        pbxproj_path = File.join(new_project_path, 'project.pbxproj')
        after_second_run_content = File.read(pbxproj_path)

        assert_equal after_first_run_content, after_second_run_content
      end
    end
  end

  # Private

  def copy_empty_project_to_tmp_folder(source = nil)
    source = source || './test/fixtures/EmptyProject'
    Dir.mktmpdir("spinjector") do |dir|
      FileUtils.copy_entry source, dir
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
