# Inject script phases into your Xcode project
#
# @author Guillaume Berthier
#

require 'optparse'
require 'xcodeproj'
require_relative 'spinjector/runner'

CONFIGURATION_FILE_PATH = 'Configuration/spinjector_configuration.yaml'.freeze

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: spinjector [options]"

  opts.on("-cName", "--configuration-path=Name", "Inject scripts using configuration file at Name location. Default is ./#{CONFIGURATION_FILE_PATH}") do |config_path|
    options[:configuration_path] = config_path
  end
end.parse!

project_path = Dir.glob("*.xcodeproj").first
raise "[Error] No xcodeproj found in #{Dir.pwd}" if project_path.nil?

runner = Runner.new(
  project_path,
  options[:configuration_path] || CONFIGURATION_FILE_PATH
)
runner.run
