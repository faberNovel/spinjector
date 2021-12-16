require 'yaml'
require_relative 'entity/configuration'
require_relative 'entity/script'
require_relative 'entity/target'
require_relative 'script_mapper'

class YAMLParser

    # The configuration to use in order to add scripts in your project
    #
    attr_reader :configuration

    def initialize(yaml_file_path)
        @configuration_description = load_yml_content(yaml_file_path)
        @configuration = Configuration.new(targets)
    end

    private

    def targets
        @configuration_description["targets"].map do |target_name, script_descriptions|
            scripts = script_descriptions.map do |script_description|
                get_script(script_description)
            end
            Target.new(target_name, scripts)
        end
    end

    def get_script(entry)
        if @configuration_description["scripts"][entry].nil?
            return get_script_by_path(entry)
        else
            return get_script_by_name(entry)
        end
    end

    def get_script_by_name(name)
        if @configuration_description["scripts"][name].nil?
            raise "[Error] Could not find script name #{name} in #{@yaml_file_path}"
        end
        script_description = @configuration_description["scripts"][name]
        ScriptMapper.new(script_description).map()
    end

    def get_script_by_path(path)
        script_description = load_yml_content(path)
        if script_description.nil?
            raise "[Error] Could not find script description at path #{path}"
        end
        ScriptMapper.new(script_description).map()
    end

    # @param [String] configuration_path
    # @return [Hash] the hash in the configuration file
    #
    def load_yml_content(configuration_path)
        raise "[Error] YAML file #{configuration_path} not found." unless File.exist?(configuration_path)
        YAML.load(File.read(configuration_path)) || {}
    end
end
