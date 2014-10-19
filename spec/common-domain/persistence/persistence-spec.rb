require 'spec-helper'

describe CommonDomain::Persistence do
  class AggregateClass
  end
  
  describe "AggregateNotFoundError" do
    it "should have a message with aggregate class and aggregate_id" do
      subject = CommonDomain::Persistence::AggregateNotFoundError.new AggregateClass, 'aggregate-847'
      expect(subject.message).to eql "Aggregate 'AggregateClass' with id 'aggregate-847' was not found."
    end
  end
end