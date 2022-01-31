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

    # @param [Configuration] configuration containing all scripts to add in each target
    #
    def update_scripts_in_targets(configuration)
        @project.targets.each do |target|
            @insertion_offset_after_compile = 0
            @insertion_offset_after_headers = 0
            target_configuration = configuration.targets.find { |conf_target| conf_target.name == target.name }
            if target_configuration == nil
                puts "No Spinjector managed build phases in target #{target}"
                remove_all_scripts(target)
                next
            end
            puts "Configurating target #{target}"
            scripts_to_apply = target_configuration.scripts_names.map { |name| BUILD_PHASE_PREFIX + name }.to_set
            native_target_script_phases = target.shell_script_build_phases.select do |bp|
                !bp.name.nil? && bp.name.start_with?(BUILD_PHASE_PREFIX)
            end
            native_target_script_phases.each do |script_phase|
                if scripts_to_apply.include?(script_phase.name)
                  # Update existing script phase with new values
                  script_configuration = target_configuration.scripts.find { |script|
                      BUILD_PHASE_PREFIX + script.name == script_phase.name
                  }
                  update_script_in_target(script_phase, script_configuration, target)
                  scripts_to_apply.delete(script_phase.name)
                elsif
                  target.build_phases.delete(script_phase)
                  # Remove now defunct script phase
                end
            end
            # We may miss scripts that are yet to be added to the pbxproj target, this is fixed in the following method
            reorder_and_add_missing_script_phases_of(target, target_configuration)
        end
    end

    private

    # @param [String] target_name
    #
    def remove_all_scripts(target)
        # Delete all the spinjector mangaed scripts from the selected target
        native_target_script_phases = target.shell_script_build_phases.select do |bp|
            !bp.name.nil? && bp.name.start_with?(BUILD_PHASE_PREFIX)
        end
        native_target_script_phases.each do |script_phase|
            target.build_phases.delete(script_phase)
        end
    end

    # @param [Xcodeproj::Project::Object::PBXNativeTarget] target to add the script phases
    # @param [Target] the target configuration describing the scripts to be added
    #
    def reorder_and_add_missing_script_phases_of(target, target_configuration)
      target_configuration.scripts.each do |script|
        spinjector_managed_phases = target.shell_script_build_phases.select do |bp|
            !bp.name.nil? && bp.name.start_with?(BUILD_PHASE_PREFIX)
        end
        current_phase = spinjector_managed_phases.find { |phase| phase.name == BUILD_PHASE_PREFIX + script.name }
        if current_phase == nil
            current_phase = add_script_in_target(script, target)
        end
        execution_position = script.execution_position
        reorder_script_phase(target, current_phase, execution_position)
      end
    end

    # @param [Script] script the script phase defined in configuration files to add to the target
    # @param [Xcodeproj::Project::Object::PBXNativeTarget] target to add the script phases
    # @return [Xcodeproj::Project::Object::PBXShellScriptBuildPhase] the newly created build phase
    #
    def add_script_in_target(script, target)
        name_with_prefix = BUILD_PHASE_PREFIX + script.name
        phase = target.new_shell_script_build_phase(name_with_prefix)
        update_script_in_target(phase, script, target)
        return phase
    end

    # @param [Xcodeproj::Project::Object::PBXShellScriptBuildPhase] phase to update with the values from the script
    # @param [Script] script the script phase defined in configuration files to add to the target
    # @param [Xcodeproj::Project::Object::PBXNativeTarget] target to add the script phase
    #
    def update_script_in_target(existing_phase, script_configuration, target)
        existing_phase.shell_script = script_configuration.source_code
        existing_phase.shell_path = script_configuration.shell_path
        existing_phase.input_paths = script_configuration.input_paths
        existing_phase.output_paths = script_configuration.output_paths
        existing_phase.input_file_list_paths = script_configuration.input_file_list_paths
        existing_phase.output_file_list_paths = script_configuration.output_file_list_paths
        existing_phase.dependency_file = script_configuration.dependency_file
        # At least with Xcode 10 `showEnvVarsInLog` is *NOT* set to any value even if it's checked and it only
        # gets set to '0' if the user has explicitly disabled this.
        if script_configuration.show_env_vars_in_log == '0'
            existing_phase.show_env_vars_in_log = script_configuration.show_env_vars_in_log
        end
    end

    # @param [Xcodeproj::Project::Object::PBXNativeTarget] target where build phases should be reordered
    # @param [Hash] script_phase to reorder
    # @param [Symbol] execution_position could be :before_compile, :after_compile, :before_headers, :after_headers
    #
    def reorder_script_phase(target, script_phase, execution_position)
        return if execution_position == :any || execution_position.to_s.empty?
        if execution_position == :after_all
            target.build_phases.move(script_phase, target.build_phases.count - 1)
            return
        end
    
        offset = -1
        # Find the point P where to add the script phase
        target_phase_type = case execution_position
                            when :before_compile
                                Xcodeproj::Project::Object::PBXSourcesBuildPhase
                            when :after_compile
                                offset = @insertion_offset_after_compile
                                @insertion_offset_after_compile += 1
                                Xcodeproj::Project::Object::PBXSourcesBuildPhase
                            when :before_headers
                                Xcodeproj::Project::Object::PBXHeadersBuildPhase
                            when :after_headers
                                offset = @insertion_offset_after_headers
                                @insertion_offset_after_headers += 1
                                Xcodeproj::Project::Object::PBXHeadersBuildPhase
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
        if target_phase_index < script_phase_index
          offset += 1
        end

        target.build_phases.move_from(script_phase_index, target_phase_index + offset)
    end

end

