module CommonDomain
  class CommandResult
    attr_reader :data
    def initialize(data = {})
      @data = data
    end
    
    def self.ok data = {}
      new({:status => :ok}.merge!(data))
    end
  end
end