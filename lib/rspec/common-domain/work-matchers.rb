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
    repository.should_receive(:begin_work) do |h = {}, &block|
      h.should eql headers
      block.call(work) unless block.nil?
    end
    work
  end
end