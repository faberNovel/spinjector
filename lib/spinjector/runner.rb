# Inject script phases into your Xcode project
#
# @author Guillaume Berthier
#

require 'xcodeproj'
require_relative './project_service'
require_relative './yaml_parser'

class Runner

  attr_reader :project

  def initialize(project_path, configuration_file_path, logger)
    raise "[Error] No xcodeproj found at #{project_path}" unless File.exist?(project_path)
    @project = Xcodeproj::Project.open(project_path)
    @configuration_file_path = configuration_file_path
    @logger = logger
  end

  def run
    configuration = YAMLParser.new(@configuration_file_path, @logger).configuration

    project_service = ProjectService.new(project, @logger)
    project_service.update_scripts_in_targets(configuration)

    @project.save()
    @logger.log "Success."
  end

end

