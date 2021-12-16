
class Configuration

    attr_reader :targets

    def initialize(targets)
        @targets = targets || []
    end
end
