module RSpec::Matchers::CommonDomainMatchers
  RSpec::Matchers.define :handle_command do |command|
    
    match do |handler|
      result = handler.can_handle_message?(command)
      if result && @aggregate_class
        result = do_match_command command
      end
      result
    end
    
    chain :with do |aggregate_class|
      @aggregate_class = aggregate_class
    end
    
    def do_match_command command
      aggregate_method_name = CommonDomain::CommandHandler::HandleDefinition.resolve_aggregate_method_name command.class
      repo = handler.repository
      aggregate = spy(:aggregate)
      allow(repo).to receive(:get_by_id).with(@aggregate_class, command.aggregate_id).and_return(aggregate)
      allow(repo).to receive(:save).with(aggregate, command.headers)
      handler.handle_message command
      @aggregate_matcher = have_received(aggregate_method_name.to_sym).with(command)
      @repo_save_matcher = have_received(:save).with(aggregate, command.headers)
      @aggregate_matcher.matches?(aggregate) && @repo_save_matcher.matches?(repo)
    end
  end
end