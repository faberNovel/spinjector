
class Script

    attr_reader :name, :source_code, :shell_path, :input_paths, :output_paths, :input_file_list_paths, :output_file_list_paths, :dependency_file, :execution_position, :show_env_vars_in_log

    def initialize(
        name,
        source_code,
        shell_path,
        input_paths,
        output_paths,
        input_file_list_paths,
        output_file_list_paths,
        dependency_file,
        execution_position,
        show_env_vars_in_log
    )
        @name = name
        @source_code = source_code
        @shell_path = shell_path
        @input_paths = input_paths
        @output_paths = output_paths
        @input_file_list_paths = input_file_list_paths
        @output_file_list_paths = output_file_list_paths
        @dependency_file = dependency_file
        @execution_position = execution_position
        @show_env_vars_in_log = show_env_vars_in_log
        verify()
    end

    def verify
        verify_execution_position()
    end

    def verify_execution_position
        case execution_position
        when :before_compile, :before_headers
            true
        when :after_compile, :after_headers
            false
        else
            raise ArgumentError, "Unknown execution position `#{execution_position}`"
        end
    end
end
