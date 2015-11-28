module CommonDomain::Persistence
  module Hookable
    def hook(after_commit: nil)
      (hooks[:after_commit] ||= []) << after_commit if after_commit
    end

    private
    
    def call_hooks(type)
      if hooks[type]
        # TODO: Rework loggable to inject instance logger method.
        # Log.debug "Calling #{type} hooks..."
        @hooks[type].map(&:call)
      end
    end

    def hooks
      @hooks ||= {}
    end
  end
end