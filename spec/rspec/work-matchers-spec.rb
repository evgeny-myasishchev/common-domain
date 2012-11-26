require 'spec-helper'

describe "work-matchers" do
  let(:repository) { Object.new }
  
  describe "begin_work" do
    it "should setup :begin_work and yield passed block with mocked work when called" do
      work = repository.should begin_work
      work.should be_instance_of RSpec::Mocks::Mock
      expect { |block| repository.begin_work(&block) }.to yield_with_args(work)
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
  end
  
  describe "get_aggregate_by_id" do
    let(:work) { mock(:work) }
    let(:aggregate_class) { mock(:aggregate_class) }
    
    it "should fail if no aggregate_class or aggregate_id supplied" do
      lambda { work.should get_aggregate_by_id }.should raise_error("aggregate_class should be supplied")
      lambda { work.should get_aggregate_by_id(aggregate_class) }.should raise_error("aggregate_id should be supplied")
    end
    
    it "should setup get_by_id with aggregate_class and aggregate_id and return setup object" do
      message_expectation = work.should get_aggregate_by_id(aggregate_class, 'aggregate-100')
      message_expectation.should be_instance_of(RSpec::Mocks::MessageExpectation)
      message_expectation.matches?(:get_by_id, aggregate_class, 'aggregate-100').should be_true
      
      #The spec will fail without this because the created expectation never called, we're just checking it
      message_expectation.never
    end
  end
end