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
      aggregate_method_name = CommonDomain::CommandHandler::HandleSyntax.resolve_aggregate_method_name command.class
      repo = handler.repository
      work = double(work)
      aggregate = spy(:aggregate)
      allow(repository).to receive(:begin_work) do |headers = {}, &block|
        block.call(work)
      end
      allow(work).to receive(:get_by_id).with(@aggregate_class, command.aggregate_id) { aggregate }
      handler.handle_message command
      @matcher = have_received(aggregate_method_name.to_sym).with(command)
      @matcher.matches?(aggregate)
    end
  end
end