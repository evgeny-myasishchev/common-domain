require 'spec-helper'

describe "work-matchers" do
  let(:repository) { double(:repository) }
  
  describe "get_by_id" do
    let(:aggregate_class) { double(:aggregate_class) }
    let(:aggregate_instance) { double(:aggregate_instance) }
    
    it "should fail if no aggregate_class or aggregate_id supplied" do
      expect(lambda { repository.to get_by_id }).to raise_error("aggregate_class should be supplied")
      expect(lambda { repository.to get_by_id(aggregate_class) }).to raise_error("aggregate_id should be supplied")
    end
    
    it "should setup get_by_id with aggregate_class and aggregate_id and return aggregate_instance" do
      expect(repository).to get_by_id(aggregate_class, 'aggregate-100').and_return aggregate_instance
      expect(repository.get_by_id(aggregate_class, 'aggregate-100')).to be aggregate_instance
    end
  end
end