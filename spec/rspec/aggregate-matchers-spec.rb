require 'spec-helper'

describe "aggregate-matchers" do
  class AggregateImplementation < CommonDomain::Aggregate
  end
  
  class DummyClass
    
  end
  
  describe "be_an_aggregate" do
    let(:aggregate) { AggregateImplementation.new }
    
    it "matches if actual is an aggregate" do
      expect(aggregate).to be_an_aggregate
    end
    
    it "does not match if actual is not an aggregate" do
      expect(DummyClass.new).not_to be_an_aggregate
    end
    
    it "should describe itself" do
      matcher = be_an_aggregate
      matcher.matches? aggregate
      expect(matcher.description).to eql "be a kind of #{CommonDomain::Aggregate}"
    end
    
    it "provides message, expected and actual on #failure_message" do
      matcher = be_an_aggregate
      matcher.matches? aggregate
      expect(matcher.failure_message).to eql "\nexpected: \"#{aggregate}\" to be a kind of CommonDomain::Aggregate\ngot: #{AggregateImplementation}\n"
    end
    
    it "provides message, expected and actual on #negative_failure_message" do
      matcher = be_an_aggregate
      matcher.matches? aggregate
      expect(matcher.failure_message_when_negated).to eql "\nexpected: \"#{aggregate}\" not to be a kind of CommonDomain::Aggregate"
    end
  end
end