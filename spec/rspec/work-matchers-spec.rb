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
end