require 'spec-helper'

describe CommonDomain::DomainEvent do
  class SampleEvent < CommonDomain::DomainEvent
    attr_reader :name, :description
  end
  
  it "should initialize attributes" do
    event = SampleEvent.new "aggregate-1", :name => "name-1", :description => "description-1"
    event.aggregate_id.should eql "aggregate-1"
    event.name.should eql "name-1"
    event.description.should eql "description-1"
  end
  
  it "should do equality by aggregate_id and version" do
    left = SampleEvent.new "aggregate-1"
    left.version = 1
    right = SampleEvent.new "aggregate-1"
    right.version = 1
    
    left.should == right
    left.should eql right
  end
end