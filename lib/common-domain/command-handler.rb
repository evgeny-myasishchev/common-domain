module CommonDomain
  class CommandHandler
    include Infrastructure::MessagesHandler
    attr_reader :repository
    def initialize(repository = nil)
      @repository = repository
    end
  end
end