# Inject script phases into your Xcode project
#
# @author Guillaume Berthier
#

require 'optparse'
require 'xcodeproj'
require 'yaml'

# @return [String] prefix used for all the build phase injected by this script
# [SPI] stands for Script Phase Injector
#
BUILD_PHASE_PREFIX = '[SPI] '.freeze

CONFIGURATION_FILE_PATH = 'Configuration/spinjector_configuration.yaml'.freeze

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: spinjector [options]"


  opts.on("-cName", "--configuration-path=Name", "Inject scripts using configuration file at Name location. Default is ./#{CONFIGURATION_FILE_PATH}") do |config_path|
    options[:configuration_path] = config_path
  end
end.parse!

# @param [Xcodeproj::Project] project
#
def remove_all_spi_script_phases(project)
  project.targets.each do |target|
    # Delete script phases no longer present in the target.
    native_target_script_phases = target.shell_script_build_phases.select do |bp|
      !bp.name.nil? && bp.name.start_with?(BUILD_PHASE_PREFIX)
    end
    native_target_script_phases.each do |script_phase|
      target.build_phases.delete(script_phase)
    end
  end
end

# @param [Xcodeproj::Project] project
# 
def inject_script_phases(project, configuration_file_path)
  configuration_file = load_yml_content(configuration_file_path)
  configuration_file.each do |target_name, script_paths|
    script_phases = (script_paths || []).flat_map do |script_path|
      load_yml_content(script_path)
    end
    warn "[Warning] No script phases found for #{target_name} target. You can add them in your configuration file at #{configuration_file_path}" unless !script_phases.empty?
    target = app_target(project, target_name)
    create_script_phases(script_phases, target)
  end
end

# @param [String] configuration_path
# @return [Hash] the hash in the configuration file
#
def load_yml_content(configuration_path)
  raise "[Error] YAML file #{configuration_path} not found." unless File.exist?(configuration_path)
  YAML.load(File.read(configuration_path)) || {}
end

# @param [Xcodeproj::Project] project
# @param [String] target_name
# @return [Xcodeproj::Project::Object::PBXNativeTarget] the target named by target_name
#
def app_target(project, target_name)
  target = project.targets.find { |t| t.name == target_name }
  raise "[Error] Invalid #{target_name} target." unless !target.nil?
  return target
end

# @param [Array<Hash>] script_phases the script phases defined in configuration files
# @param [Xcodeproj::Project::Object::PBXNativeTarget] target to add the script phases
#
def create_script_phases(script_phases, target)
  script_phases.each do |script_phase|
    name_with_prefix = BUILD_PHASE_PREFIX + script_phase["name"]
    phase = target.new_shell_script_build_phase(name_with_prefix)
    script = File.read(script_phase["script_path"])
    phase.shell_script = script
    phase.shell_path = script_phase["shell_path"] || '/bin/sh'
    phase.input_paths = script_phase["input_paths"]
    phase.output_paths = script_phase["output_paths"]
    phase.input_file_list_paths = script_phase["input_file_list_paths"]
    phase.output_file_list_paths = script_phase["output_file_list_paths"]
    phase.dependency_file = script_phase["dependency_file"]
    # At least with Xcode 10 `showEnvVarsInLog` is *NOT* set to any value even if it's checked and it only
    # gets set to '0' if the user has explicitly disabled this.
    if (show_env_vars_in_log = script_phase.fetch("show_env_vars_in_log", '1')) == '0'
      phase.show_env_vars_in_log = show_env_vars_in_log
    end

    execution_position = script_phase["execution_position"] || :before_compile
    reorder_script_phase(target, phase, execution_position)
  end
end

# @param [Xcodeproj::Project::Object::PBXNativeTarget] target where build phases should be reordered
# @param [Hash] script_phase to reorder
# @param [Symbol] execution_position could be :before_compile, :after_compile, :before_headers, :after_headers
#
def reorder_script_phase(target, script_phase, execution_position)
  return if execution_position == :any || execution_position.to_s.empty?

  # Find the point P where to add the script phase
  target_phase_type = case execution_position
                      when :before_compile, :after_compile
                        Xcodeproj::Project::Object::PBXSourcesBuildPhase
                      when :before_headers, :after_headers
                        Xcodeproj::Project::Object::PBXHeadersBuildPhase
                      else
                        raise ArgumentError, "Unknown execution position `#{execution_position}`"
                      end

  # Decide whether to add script_phase before or after point P
  order_before = case execution_position
                 when :before_compile, :before_headers
                   true
                 when :after_compile, :after_headers
                   false
                 else
                   raise ArgumentError, "Unknown execution position `#{execution_position}`"
                 end

  # Get the first build phase index of P
  target_phase_index = target.build_phases.index do |bp|
    bp.is_a?(target_phase_type)
  end
  return if target_phase_index.nil?

  # Get the script phase we want to reorder index
  script_phase_index = target.build_phases.index do |bp|
    bp.is_a?(Xcodeproj::Project::Object::PBXShellScriptBuildPhase) && !bp.name.nil? && bp.name == script_phase.name
  end

  # Move script phase to P if needed
  if (order_before && script_phase_index > target_phase_index) ||
    (!order_before && script_phase_index < target_phase_index)
    target.build_phases.move_from(script_phase_index, target_phase_index)
  end
end

project_path = Dir.glob("*.xcodeproj").first
project = Xcodeproj::Project.open(project_path)
raise "[Error] No xcodeproj found" unless !project.nil?
remove_all_spi_script_phases(project)
configuration_file_path = options[:configuration_path] || CONFIGURATION_FILE_PATH
inject_script_phases(project, configuration_file_path)
project.save()
puts "Success."
