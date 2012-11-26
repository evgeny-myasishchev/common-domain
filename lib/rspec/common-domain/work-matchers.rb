RSpec::Matchers.define :begin_work do
  match do |repository|
    work = mock(:work)
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
    repository.should_receive(:begin_work) do |h, &block|
      h.should eql headers
      block.call(work) unless block.nil?
    end
    work
  end
end


# Sample:
#   work.should get_aggregate_by_id(Acount, 'account-993').and_return(account_instance)
RSpec::Matchers.define :get_aggregate_by_id do |aggregate_class, aggregate_id|
  raise "aggregate_class should be supplied" if aggregate_class.nil?
  raise "aggregate_id should be supplied" if aggregate_id.nil?
  
  match do |repo_or_work|
    repo_or_work.should_receive(:get_by_id).with(aggregate_class, aggregate_id)
  end
end
