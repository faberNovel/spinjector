require_relative 'entity/script'

class ScriptMapper

    def initialize(script_hash)
        @script_hash = script_hash
        verify_syntax
    end

    def map
        script_code = @script_hash["script"] || load_script(@script_hash["script_path"])
        Script.new(
            @script_hash["name"],
            script_code,
            @script_hash["shell_path"] || '/bin/sh',
            @script_hash["input_paths"] || [],
            @script_hash["output_paths"] || [],
            @script_hash["input_file_list_paths"] || [],
            @script_hash["output_file_list_paths"] || [],
            @script_hash["dependency_file"],
            @script_hash["execution_position"] || :before_compile,
            @script_hash["show_env_vars_in_log"],
            @script_hash["always_out_of_date"]
        )
    end

    def verify_syntax
        raise "[Error] Invalid script description #{@script_hash}" unless @script_hash.is_a?(Hash)
        raise "[Error] Script must have a name and an associated script" unless @script_hash.has_key?("name") && @script_hash.has_key?("script") || @script_hash.has_key?("script_path")
        raise "[Error] Invalid name in script #{@script_hash}" unless !@script_hash["name"].nil?
    end

    def load_script(path)
        raise "[Error] File #{path} does not exist" unless !path.nil? && File.exist?(path)
        File.read(path)
    end
end