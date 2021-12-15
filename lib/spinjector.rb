# Inject script phases into your Xcode project
#
# @author Guillaume Berthier
#

require 'optparse'
require 'xcodeproj'
require_relative 'spinjector/project_service'
require_relative 'spinjector/yaml_parser'

CONFIGURATION_FILE_PATH = 'Configuration/spinjector_configuration.yaml'.freeze

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: spinjector [options]"

  opts.on("-cName", "--configuration-path=Name", "Inject scripts using configuration file at Name location. Default is ./#{CONFIGURATION_FILE_PATH}") do |config_path|
    options[:configuration_path] = config_path
  end
end.parse!

project_path = Dir.glob("*.xcodeproj").first
project = Xcodeproj::Project.open(project_path)
raise "[Error] No xcodeproj found" unless !project.nil?

configuration_file_path = options[:configuration_path] || CONFIGURATION_FILE_PATH
configuration = YAMLParser.new(configuration_file_path).configuration

project_service = ProjectService.new(project)
project_service.remove_all_scripts()
project_service.add_scripts_in_targets(configuration)

project.save()
puts "Success."
