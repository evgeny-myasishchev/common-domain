module RSpec::Matchers::CommonDomainMatchers
  
  module Helpers
    def dummy_headers
      {dummy_header_1: 'dummy-value-1', dummy_header_2: 'dummy-value-2'}
    end
  
    def with_dummy_headers
      hash_including(dummy_headers)
    end
  end
  
  
  # Sample:
  #   expect(repository).to get_by_id(Acount, 'account-993').and_return(account_instance)
  RSpec::Matchers.define :get_by_id do |aggregate_class, aggregate_id|
    raise "aggregate_class should be supplied" if aggregate_class.nil?
    raise "aggregate_id should be supplied" if aggregate_id.nil?
    @aggregate = nil
    match do |repository|
      raise 'please provide aggregate instance with and_return chain' if @aggregate.nil?
      expect(repository).to receive(:get_by_id).with(aggregate_class, aggregate_id).
        and_return(@aggregate)
      true
    end
    chain :and_return do |aggregate|
      @aggregate = aggregate
    end
    chain :and_save do |headers|
      raise 'please provide aggregate instance with and_return chain' if @aggregate.nil?
      raise 'please provide expected headers to save with the aggregate' if headers.nil?
      expect(repository).to receive(:save).with(@aggregate, headers)
    end
  end
end

RSpec.configure do |c|
  c.include RSpec::Matchers::CommonDomainMatchers::Helpers
end