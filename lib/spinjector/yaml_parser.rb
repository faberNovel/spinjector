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
        if @configuration_description["targets"].nil?
            puts "[Warning] There is no target in your configuration file."
            return
        end
        @configuration_description["targets"].map do |target_name, script_entries|
            if script_entries.nil?
                puts "[Warning] There is no scripts in your configuration file under target #{target_name}"
                return
            end
            scripts = script_entries.map do |entry|
                get_script(entry)
            end
            Target.new(target_name, scripts)
        end
    end

    def get_script(entry)
        script = 
            if !@configuration_description["scripts"].nil? && !@configuration_description["scripts"][entry].nil?
                get_script_by_name(entry)
            elsif File.exist?(entry)
                get_script_by_path(entry)
            else
                raise "[Error] Script #{entry} does not exist" unless !script.nil?
            end
    end

    def get_script_by_name(name)
        script_description = @configuration_description["scripts"][name]
        ScriptMapper.new(script_description).map()
    end

    def get_script_by_path(path)
        script_description = load_yml_content(path)
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
