module RSpec::Matchers::CommonDomainMatchers
  def self.setup_work_mock(mock)
    mock.stub(on_committed: nil)
  end
    
  RSpec::Matchers.define :begin_work do
    match do |repository|
      work = mock(:work)
      RSpec::Matchers::CommonDomainMatchers::setup_work_mock work
      repository.should_receive(:begin_work) do |headers = {}, &block|
        block.call(work)
      end
      work
    end
  end

  RSpec::Matchers.define :begin_work_with_headers do |headers|
    raise "Headers must be supplied" if headers.nil?
    match do |repository|
      work = mock(:work)
      RSpec::Matchers::CommonDomainMatchers::setup_work_mock work
      repository.should_receive(:begin_work) do |h, &block|
        h.should eql headers
        block.call(work) unless block.nil?
      end
      work
    end
  end
  
  RSpec::Matchers.define :register_on_committed do
    match do |work|
      on_committed = nil
      work.should_receive(:on_committed) do |&block|
        on_committed = block
      end
      lambda { on_committed.call unless on_committed.nil? }
    end
  end
  
  # Sample:
  #   work.should get_and_return_aggregate(Acount, 'account-993').and_return(account_instance)
  RSpec::Matchers.define :get_and_return_aggregate do |aggregate_class, aggregate_id, aggregate|
    raise "aggregate_class should be supplied" if aggregate_class.nil?
    raise "aggregate_id should be supplied" if aggregate_id.nil?

    match do |repo_or_work|    
      repo_or_work.should_receive(:get_by_id).with(aggregate_class, aggregate_id).and_return(aggregate)
    end
  end
end
