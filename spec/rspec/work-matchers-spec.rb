require 'spec-helper'

describe "work-matchers" do
  let(:repository) { Object.new }
  
  describe "begin_work" do
    it "should setup :begin_work and yield passed block with mocked work when called" do
      work = repository.should begin_work
      work.should be_instance_of RSpec::Mocks::Mock
      expect { |block| repository.begin_work(&block) }.to yield_with_args(work)
    end
    
    it "should stub on_committed" do
      work = repository.should begin_work
      work.on_committed.should be_nil
      repository.begin_work { }
    end
  end
  
  describe "begin_work_with_headers" do
    it "should fail if no headers supplied" do
      lambda { repository.should begin_work_with_headers }.should raise_error("Headers must be supplied")
    end
    
    it "should setup :begin_work and yield passed block with mocked work when called" do
      headers = {header1: 'header-1', header2: 'header-2'}
      work = repository.should begin_work_with_headers headers
      work.should be_instance_of RSpec::Mocks::Mock
      expect { |block| repository.begin_work(headers, &block) }.to yield_with_args(work)
    end
    
    it "should make sure that supplied headers match" do
      headers = {header: 'header-100'}
      work = repository.should begin_work_with_headers headers
      lambda { repository.begin_work({wrong: 'header-100'}) }.should raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
    
    it "should stub on_committed" do
      work = repository.should begin_work_with_headers({header: 'header-1'})
      work.on_committed.should be_nil
      repository.begin_work({header: 'header-1'}) { }
    end
  end
  
  describe "get_and_return_aggregate" do
    let(:work) { mock(:work) }
    let(:aggregate_class) { mock(:aggregate_class) }
    let(:aggregate_instance) { mock(:aggregate_instance) }
    
    it "should fail if no aggregate_class or aggregate_id supplied" do
      lambda { work.should get_and_return_aggregate }.should raise_error("aggregate_class should be supplied")
      lambda { work.should get_and_return_aggregate(aggregate_class) }.should raise_error("aggregate_id should be supplied")
    end
    
    it "should setup get_by_id with aggregate_class and aggregate_id and return aggregate_instance" do
      work.should get_and_return_aggregate(aggregate_class, 'aggregate-100', aggregate_instance)
      work.get_by_id(aggregate_class, 'aggregate-100').should be aggregate_instance
    end
  end
  
  describe "register_on_committed" do
    let(:work) { mock(:work) }
    it "should setup on_committed expectation and return a callback to trigger committed callback" do
      callback = work.should register_on_committed
      expect { |block|
        work.on_committed &block
        callback.call
      }.to yield_control
    end
    
    it "should call the block only if the callback was registered" do
      callback = work.should register_on_committed
      lambda { callback.call }.should_not raise_error
      work.on_committed {}
    end
  end
end