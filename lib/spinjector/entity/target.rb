
class Target

    attr_reader :name, :scripts

    def initialize(name, scripts)
        @name = name
        @scripts = scripts || []
    end

    def scripts_names
        @scripts.map { |script| script.name }
    end
end
