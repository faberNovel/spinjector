require_relative 'entity/script'

class ScriptMapper

    def initialize(script_hash)
        @script_hash = script_hash
    end

    def map()
        script_code = @script_hash["script"] || load_script(@script_hash["script_path"])
        Script.new(
            @script_hash["name"],
            script_code,
            @script_hash["shell_path"] || '/bin/sh',
            @script_hash["input_paths"],
            @script_hash["output_paths"],
            @script_hash["input_file_list_paths"],
            @script_hash["output_file_list_paths"],
            @script_hash["dependency_file"],
            @script_hash["execution_position"] || :before_compile,
            @script_hash["show_env_vars_in_log"] || '0'
        )
    end
        
    def load_script(path)
        raise "[Error] File #{path} does not exist" unless File.exist?(path)
        File.read(path)
    end
end