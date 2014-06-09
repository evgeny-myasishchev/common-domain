module RSpec::Matchers::CommonDomainMatchers
  def self.setup_work_mock(double)
    allow(double).to receive(on_committed: nil)
  end
    
  RSpec::Matchers.define :begin_work do
    match do |repository|
      work = double(:work)
      RSpec::Matchers::CommonDomainMatchers::setup_work_mock work
      expect(repository).to receive(:begin_work) do |headers = {}, &block|
        block.call(work)
      end
      work
    end
  end

  RSpec::Matchers.define :begin_work_with_headers do |headers|
    raise "Headers must be supplied" if headers.nil?
    match do |repository|
      work = double(:work)
      RSpec::Matchers::CommonDomainMatchers::setup_work_mock work
      expect(repository).to receive(:begin_work) do |h, &block|
        expect(h).to eql headers
        block.call(work) unless block.nil?
      end
      work
    end
  end
  
  RSpec::Matchers.define :register_on_committed do
    match do |work|
      on_committed = nil
      expect(work).to receive(:on_committed) do |&block|
        on_committed = block
      end
      lambda { on_committed.call unless on_committed.nil? }
    end
  end
  
  # Sample:
  #   expect(work).to get_and_return_aggregate(Acount, 'account-993').and_return(account_instance)
  RSpec::Matchers.define :get_and_return_aggregate do |aggregate_class, aggregate_id, aggregate|
    raise "aggregate_class should be supplied" if aggregate_class.nil?
    raise "aggregate_id should be supplied" if aggregate_id.nil?

    match do |repo_or_work|    
      expect(repo_or_work).to receive(:get_by_id).with(aggregate_class, aggregate_id).and_return(aggregate)
      true
    end
  end
end
