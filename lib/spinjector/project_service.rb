require 'xcodeproj'
require_relative 'entity/configuration'
require_relative 'entity/script'
require_relative 'entity/target'

# @return [String] prefix used for all the build phase injected by this script
# [SPI] stands for Script Phase Injector
#
BUILD_PHASE_PREFIX = '[SPI] '.freeze

class ProjectService

    # @param [Xcodeproj::Project] project
    #
    def initialize(project)
        @project = project
    end

    def remove_all_scripts
        @project.targets.each do |target|
            # Delete script phases no longer present in the target.
            native_target_script_phases = target.shell_script_build_phases.select do |bp|
                !bp.name.nil? && bp.name.start_with?(BUILD_PHASE_PREFIX)
            end
            native_target_script_phases.each do |script_phase|
                target.build_phases.delete(script_phase)
            end
        end
    end

    def add_scripts_in_targets(configuration)
        configuration.targets.each do |target|
            xcode_target = app_target(target.name)
            add_scripts_in_target(target.scripts, xcode_target)
        end
    end

    private

    # @param [Xcodeproj::Project] project
    # @param [String] target_name
    # @return [Xcodeproj::Project::Object::PBXNativeTarget] the target named by target_name
    #
    def app_target(target_name)
        target = @project.targets.find { |t| t.name == target_name }
        raise "[Error] Invalid #{target_name} target." unless !target.nil?
        return target
    end

    # @param [Array<Script>] scripts the script phases defined in configuration files
    # @param [Xcodeproj::Project::Object::PBXNativeTarget] target to add the script phases
    #
    def add_scripts_in_target(scripts, target)
        scripts.each do |script|
            name_with_prefix = BUILD_PHASE_PREFIX + script.name
            phase = target.new_shell_script_build_phase(name_with_prefix)
            phase.shell_script = script.source_code
            phase.shell_path = script.shell_path
            phase.input_paths = script.input_paths
            phase.output_paths = script.output_paths
            phase.input_file_list_paths = script.input_file_list_paths
            phase.output_file_list_paths = script.output_file_list_paths
            phase.dependency_file = script.dependency_file
            # At least with Xcode 10 `showEnvVarsInLog` is *NOT* set to any value even if it's checked and it only
            # gets set to '0' if the user has explicitly disabled this.
            if script.show_env_vars_in_log == '0'
                phase.show_env_vars_in_log = script.show_env_vars_in_log
            end
            execution_position = script.execution_position
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
        if (order_before && script_phase_index > target_phase_index) || (!order_before && script_phase_index < target_phase_index)
            target.build_phases.move_from(script_phase_index, target_phase_index)
        end
    end
end
